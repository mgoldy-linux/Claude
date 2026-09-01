/*======================================================================================
  Capture-OldValidator-Baseline.sql
  Ground-truth OLD verdict + message for the asi_Order_Validator port.

  WHY THIS EXISTS
    kb_Order_Validator_v2's only real output is a popup, and the popup was never
    persisted anywhere -- so the existing Compare-Rules-OldVsNew.sql harness can only
    diff the surcharge flag and header notes. That leaves the thing that matters most
    (nine checks whose entire product is prose) unverified.

    This script calls dbo.kb_fnt_br_order_validator_v2 DIRECTLY, reconstructing its two
    TVP payloads from the persisted tables. No DLL swap, no manual save, no transcribing
    popups off a screen. Run it over a corpus of existing orders to get the OLD side for
    hundreds of orders in one pass.

  APPROXIMATION (read this before trusting a diff)
    The C# builds the TVP from the LIVE DataWindow; this builds it from disk. For an
    order with unsaved edits those differ. For already-saved orders they match, and the
    TVF only reads three of the 37 TVP columns (item_id, qty_open, extended_price), all
    of which persist. So: run against saved orders only, and don't edit them mid-run.

  SEQUENCE
    STEP 0  verify the column mappings below (REQUIRED -- do not skip)
    STEP 1  create the capture table
    STEP 2  choose the corpus
    STEP 3  capture OLD (this script)
    STEP 4  deploy asi_Order_Validator to BRR, re-save the corpus, then diff
    STEP 5  cleanup

  Run in the Business Rules (P21BusinessRules) or P21Play DB. NOT Prod.
======================================================================================*/


/*--------------------------------------------------------------------------------------
  STEP 0 -- VERIFY COLUMN MAPPINGS.

  *** RUN 2026-09-01 (P21BusinessRules). (a) (b) (c) (e) are RESOLVED -- do not re-run. ***

    (a) RESOLVED: oe_hdr has NO ship_to_id column. The ship-to is address_id.
                  STEP 3 updated.
    (b) RESOLVED: oe_line.complete exists ('Y'/'N'); complete_flag does not. As written.
    (c) RESOLVED: inv_mast.product_type exists. As written.
    (e) RESOLVED: oe_hdr.order_type is an INT (e.g. 706); code_group_no 1215 resolves it
                  to a description ('OE'). 'CUO Entry' = code_no 1344 and exists, so
                  scenario 7's consignment exemption is live. STEP 3 lookup is correct.
                  NOTE for the business: code 3056 'Consigned Manufacturer Rep Order Entry'
                  is also consignment but is NOT exempted by the TVF.

    (d) RESOLVED by direct observation: d_oe_hdr_credit.credit_status is PLAIN
        customer.credit_status, NOT kb_view_customer's corporate rollup.
        Evidence -- order 6108236, customer 3025940 (child account,
        corp_address_id 1020940 <> id 3025940): plain = COD, rollup = NORMAL, and the
        Order Entry Credit tab shows COD. @use_rollup = 'N' in STEP 3.

        *** THIS IS ALSO A LIVE PRODUCTION FINDING, independent of the port. ***
        kb_Order_Validator_v2 reads PLAIN credit status; kb_proc_br_oe_hdr_note (the
        workflow rule) reads the ROLLUP via kb_view_customer. They disagree for 577
        customers. For a child account like the one above the validator sees COD and
        applies the COD/CASH/PREPAY freight rules (scenario 6a can force the order to
        Will Advise), while the workflow rule sees NORMAL, exits early, and never writes
        the 'Freight Quote Required' note. Scenario 6b -- the check that prompts someone
        to take the order back OFF Will Advise -- requires that note to exist, so it can
        never fire for these customers. Raise with whoever owns the freight-quote
        workflow; do not "fix" it inside this port.

  The queries below are kept for re-verification after an environment refresh.
--------------------------------------------------------------------------------------*/
-- (a) ship-to on the order header: ship_to_id vs address_id
--     (Compare-Rules-OldVsNew.sql's B1 finder used h.address_id AS ship_to_id)
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'oe_hdr' AND COLUMN_NAME IN ('ship_to_id','address_id','carrier_id',
       'packing_basis','freight_code_uid','requested_date','order_type','customer_id');

-- (b) line completion + bundle flag. Note: oe_line.complete is 'Y'/'N', but
--     oe_line.complete_flag uses 'completed' -- do NOT mix them up.
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'oe_line' AND COLUMN_NAME IN ('complete','complete_flag','qty_ordered',
       'extended_price','delete_flag','inv_mast_uid');

-- (c) product_type ('B' = bundle) is derived from the item, not stored on oe_line.
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'inv_mast' AND COLUMN_NAME LIKE '%product_type%';

-- (d) credit status: the rule reads d_oe_hdr_credit.credit_status. Confirm whether that
--     mirrors customer.credit_status or an order-level snapshot on oe_hdr.
SELECT 'customer' AS src, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'customer' AND COLUMN_NAME = 'credit_status'
UNION ALL
SELECT 'oe_hdr', COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'oe_hdr' AND COLUMN_NAME LIKE '%credit_status%';

-- (e) SANITY: order_type must resolve to a DESCRIPTION, not a code.
--     The TVF tests @order_type NOT IN ('CUO Entry'). Its own commented-out block
--     (lines 269-271) documents the lookup: code_group_no 1215, code_no = oe_hdr.order_type.
--     If this returns codes rather than names, scenario 7 has never fired correctly.
SELECT TOP 20 h.order_no, h.order_type AS raw_code,
       (SELECT code_description FROM p21_view_codes
        WHERE code_group_no = 1215 AND code_no = h.order_type) AS resolved_description
FROM   oe_hdr h WHERE h.order_type IS NOT NULL ORDER BY h.order_date DESC;

-- (d) THE ONE STILL OPEN. Pick an order from this list, open it in Order Entry, and read
--     the Credit tab's Credit Status field. Whichever column it matches -- plain or
--     rollup -- is what d_oe_hdr_credit.credit_status is. Set @use_rollup in STEP 3.
SELECT TOP 5 h.order_no, h.order_date, c.customer_id, c.customer_name,
       c.credit_status AS plain,
       CASE WHEN a.corp_address_id <> a.id OR ISNULL(c.credit_limit,0.0) = 0.0
            THEN corp.credit_status ELSE c.credit_status END AS rollup
FROM   oe_hdr h
JOIN   customer c    ON c.customer_id = h.customer_id
LEFT   JOIN address  a    ON a.id = c.customer_id
LEFT   JOIN customer corp ON corp.customer_id = a.corp_address_id
WHERE  ISNULL(c.credit_status,'~') <> ISNULL(
         CASE WHEN a.corp_address_id <> a.id OR ISNULL(c.credit_limit,0.0) = 0.0
              THEN corp.credit_status ELSE c.credit_status END,'~')
ORDER BY h.order_date DESC;
GO


/*--------------------------------------------------------------------------------------
  STEP 1 -- capture table (test-only; dropped in STEP 5)

  DROPS AND RECREATES unconditionally. This is a scratch table and each run is a fresh
  baseline, so an "only create if absent" guard just leaves a stale schema behind when the
  column list changes -- which is exactly how you get "Invalid column name" from STEP 3.
  If you need to keep a previous capture, rename it before running this.
--------------------------------------------------------------------------------------*/
IF OBJECT_ID('dbo.asi_validator_baseline') IS NOT NULL
    DROP TABLE dbo.asi_validator_baseline;

CREATE TABLE dbo.asi_validator_baseline (
        order_no        VARCHAR(8)    NOT NULL PRIMARY KEY,
        captured_at     DATETIME      NOT NULL CONSTRAINT DF_avb_cap DEFAULT (GETDATE()),
        would_run       VARCHAR(1)    NOT NULL,   -- 'Y' = the rule would have called the TVF
        skip_reason     VARCHAR(40)   NULL,       -- why not, when would_run = 'N'
        success_bool    VARCHAR(1)    NULL,
        err_code        VARCHAR(20)   NULL,       -- parsed [v2errNN] tag
        result_message  VARCHAR(4000) NULL,
        atlas_surcharge VARCHAR(1)    NULL,
        line_count      INT           NULL,
        qualifying_open INT           NULL,       -- the C#'s num2
        -- Credit status source is ambiguous: oe_hdr has NO credit_status column, so the
        -- rule's d_oe_hdr_credit.credit_status is derived, and plain vs corporate-rollup
        -- disagree for 577 customers (196 orders in a 90-day corpus). Capture both so a
        -- wrong guess is visible instead of silent.
        credit_plain    VARCHAR(8)    NULL,
        credit_rollup   VARCHAR(8)    NULL,
        credit_used     VARCHAR(8)    NULL,       -- the one actually passed to the TVF
        credit_ambiguous VARCHAR(1)   NULL,       -- 'Y' = the two disagree for this order
        -- A TVF that throws is NOT a harness bug to hide: the live C# catch swallows the
        -- same exception and the order saves UNVALIDATED. Capturing it makes that
        -- fail-open population countable.
        tvf_error       VARCHAR(500)  NULL
    );
GO


/*--------------------------------------------------------------------------------------
  STEP 2 -- corpus. Default: every saved order the rule would actually validate,
  most recent first. Tighten the TOP / date window to taste.
--------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#corpus') IS NOT NULL DROP TABLE #corpus;

SELECT TOP 500 h.order_no
INTO   #corpus
FROM   oe_hdr h
WHERE  ISNULL(h.rma_flag,'N')    <> 'Y'          -- C# skip conditions, mirrored
  AND  ISNULL(h.cancel_flag,'N') <> 'Y'
  AND  h.quote_type IS NULL                      -- no literal 'quote' column on oe_hdr
  AND  ISNULL(h.delete_flag,'N') <> 'Y'
  AND  h.order_date >= DATEADD(DAY, -90, GETDATE())
ORDER BY h.order_date DESC;

CREATE CLUSTERED INDEX ix_corpus ON #corpus(order_no);
GO


/*--------------------------------------------------------------------------------------
  STEP 3 -- CAPTURE. Row-by-row by necessity: the TVF takes TVPs, so there is no
  set-based form. ~500 orders runs in well under a minute.
--------------------------------------------------------------------------------------*/
SET NOCOUNT ON;

-- WHICH CREDIT STATUS DOES THE RULE ACTUALLY SEE?
--   'Y' = kb_view_customer's corporate rollup   |   'N' = plain customer.credit_status
--
-- RESOLVED 2026-09-01 by direct observation. Order 6108236 / customer 3025940
-- (Superior of Illinois, a child account: corp_address_id 1020940 <> id 3025940):
--     plain = COD    rollup = NORMAL    Order Entry Credit tab = COD
-- => d_oe_hdr_credit.credit_status is PLAIN customer.credit_status. Use 'N'.
--
-- Rows where the two disagree are still flagged credit_ambiguous = 'Y' so the exposure
-- stays visible in the summary at the end of this step.
DECLARE @use_rollup VARCHAR(1) = 'N';   -- <<< CONFIRMED: plain, not rollup

DECLARE @order_no       VARCHAR(8),
        @req_date       DATETIME,
        @date_created   DATETIME,
        @order_date     DATETIME,
        @fcuid          INT,
        @stid           DECIMAL(19,0),
        @carrier_name   VARCHAR(255),
        @packing_basis  VARCHAR(16),
        @custid         DECIMAL(19,0),
        @ccstatus       VARCHAR(8),
        @cc_plain       VARCHAR(8),
        @cc_rollup      VARCHAR(8),
        @order_type     VARCHAR(255),
        @line_count     INT,
        @qualifying     INT,
        @sb             VARCHAR(1),
        @rm             VARCHAR(4000),
        @atlas          VARCHAR(1),
        @tvf_error      VARCHAR(500);

DECLARE @items dbo.kb_TableTypeItemsOnOrder;
DECLARE @notes dbo.kb_TableTypeFourStrings;
DECLARE @pay   dbo.kb_TableTypeFourStrings;   -- always empty: the TVF's only use of
                                              -- @payment_info fed @cc_used, which is dead

DELETE FROM dbo.asi_validator_baseline
WHERE  order_no IN (SELECT order_no FROM #corpus);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT order_no FROM #corpus;
OPEN cur;
FETCH NEXT FROM cur INTO @order_no;

WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM @items;
    DELETE FROM @notes;

    /* ---- Rebuild kb_TableTypeItemsOnOrder ------------------------------------------
       Mirrors the C# loop exactly for the three columns the TVF reads:
         - skips delete_flag = 'Y' and NULL item_id
         - qty_open = qty_ordered when the line QUALIFIES
                      (qty_ordered > 0, not complete, not a bundle), else 0
         - extended_price passed through raw
       Only three columns drive a LIVE check (item_id, qty_open, extended_price). Four more
       must be populated anyway, purely to keep the TVF from crashing:

         qty_allocated_uom, unit_size, unit_price, pricing_unit_size

       They feed @amt_to_pay (TVF line 312), whose only consumer is commented-out scenario
       11 -- a dead value. But it divides by pricing_unit_size, and its guard is broken:
           ISNULL(pricing_unit_size, 0.00001)
       ISNULL returns the type of its FIRST argument, and pricing_unit_size is
       decimal(19,4), so 0.00001 is converted to 0.0000 and the guard divides by zero.
       Leaving these NULL makes every order throw. (In oe_line, pricing_unit_size is never
       NULL or zero across 10.4M rows -- so with real values this cannot fire here. The
       live rule reads the DataWindow instead, where a mid-entry line could still be NULL;
       that path is unproven but is a genuine latent fail-open, since the TVF error is
       swallowed by the C# catch and the order saves unvalidated.)

       The remaining 30 columns stay NULL: the TVF never reads them (verified against its
       source -- every consumer sits in commented-out or unreachable code).
    ---------------------------------------------------------------------------------- */
    INSERT INTO @items (item_id, qty_open, extended_price,
                        qty_allocated_uom, unit_size, unit_price, pricing_unit_size)
    SELECT im.item_id,
           CASE WHEN ISNULL(l.qty_ordered,0) > 0
                 AND ISNULL(l.complete,'N') <> 'Y'
                 AND ISNULL(im.product_type,'') <> 'B'
                THEN ISNULL(l.qty_ordered,0) ELSE 0 END,
           l.extended_price,
           l.qty_allocated,
           l.unit_size,
           l.unit_price,
           l.pricing_unit_size
    FROM   oe_line l
    JOIN   inv_mast im ON im.inv_mast_uid = l.inv_mast_uid
    WHERE  l.order_no = @order_no
      AND  ISNULL(l.delete_flag,'N') <> 'Y'
      AND  im.item_id IS NOT NULL;

    /* ---- Rebuild kb_TableTypeFourStrings (header notes) -----------------------------
       s1 = topic, s2 = notepad_class_id, s3 = mandatory, s4 = note.
       Positional binding -- the type has no named contract, so order matters.
    ---------------------------------------------------------------------------------- */
    INSERT INTO @notes (s1, s2, s3, s4)
    SELECT n.topic, n.notepad_class_id, n.mandatory, CAST(n.note AS VARCHAR(MAX))
    FROM   oe_hdr_notepad n
    WHERE  n.order_no = @order_no
      AND  ISNULL(n.delete_flag,'N') <> 'Y';

    SELECT @line_count = COUNT(*),
           @qualifying = SUM(CASE WHEN qty_open > 0 THEN 1 ELSE 0 END)
    FROM   @items;

    /* ---- Live scalar parameters (9 of 57 -- the rest are unread by the TVF) -------- */
    SELECT @req_date      = h.requested_date,
           @date_created  = h.date_created,
           @order_date    = h.order_date,
           @fcuid         = h.freight_code_uid,
           -- CONFIRMED 2026-09-01: oe_hdr has NO ship_to_id column. The ship-to is
           -- address_id, which is what kb_proc_br_oe_hdr_note reads and what feeds
           -- p21_view_ship_to.ship_to_id. (The d_oe_header DATAWINDOW exposes the same
           -- value under the name ship_to_id -- that is a DataWindow alias, not a column.)
           @stid          = h.address_id,
           @packing_basis = h.packing_basis,
           @custid        = h.customer_id,
           -- carrier NAME, not id: the TVF matches kb_view_carrier.name
           @carrier_name  = (SELECT a.name FROM p21_view_address a WHERE a.id = h.carrier_id),
           -- order_type must be the DESCRIPTION, not the code. CONFIRMED 2026-09-01:
           -- oe_hdr.order_type is an INT (e.g. 706); code_group_no 1215 resolves 706 -> 'OE'.
           -- The live C# reads d_oe_header.order_type as a STRING, so the DataWindow is
           -- already handing over the description -- which is what the TVF's own removed
           -- block (its lines 269-271) used to look up. This lookup reproduces that.
           -- CAVEAT: the removed block wrapped it in ISNULL(...,'OE'). We do not, so an
           -- unresolvable code yields NULL here and `NULL NOT IN ('CUO Entry')` is UNKNOWN,
           -- suppressing scenario 7. If the DataWindow supplies '' instead of NULL the live
           -- rule WOULD fire it. Immaterial while every order resolves cleanly; revisit if
           -- the capture shows NULL order_type rows.
           @order_type    = (SELECT code_description FROM p21_view_codes
                             WHERE code_group_no = 1215 AND code_no = h.order_type),
           -- Both credit-status candidates. @use_rollup (top of STEP 3) selects which one
           -- is passed to the TVF; the other is captured for comparison.
           @cc_plain      = (SELECT c.credit_status
                             FROM   customer c WHERE c.customer_id = h.customer_id),
           @cc_rollup     = (SELECT CASE WHEN a.corp_address_id <> a.id
                                           OR ISNULL(c.credit_limit,0.0) = 0.0
                                         THEN corp.credit_status
                                         ELSE c.credit_status END
                             FROM   customer c
                             LEFT   JOIN address  a    ON a.id = c.customer_id
                             LEFT   JOIN customer corp ON corp.customer_id = a.corp_address_id
                             WHERE  c.customer_id = h.customer_id)
    FROM   oe_hdr h
    WHERE  h.order_no = @order_no;

    SET @ccstatus = CASE WHEN @use_rollup = 'Y' THEN @cc_rollup ELSE @cc_plain END;

    -- Mirror the C#'s num2 > 0 short-circuit: with no qualifying open line the real rule
    -- returns success WITHOUT calling the TVF, so calling it here would invent a verdict.
    IF ISNULL(@qualifying,0) = 0
    BEGIN
        INSERT INTO dbo.asi_validator_baseline
            (order_no, would_run, skip_reason, line_count, qualifying_open,
             credit_plain, credit_rollup, credit_used, credit_ambiguous)
        VALUES (@order_no, 'N', 'no qualifying open lines', @line_count, ISNULL(@qualifying,0),
                @cc_plain, @cc_rollup, @ccstatus,
                CASE WHEN ISNULL(@cc_plain,'~') <> ISNULL(@cc_rollup,'~') THEN 'Y' ELSE 'N' END);
    END
    ELSE
    BEGIN
        SET @sb = NULL; SET @rm = NULL; SET @atlas = NULL; SET @tvf_error = NULL;

        BEGIN TRY
        SELECT @sb = success_bool, @rm = result_message, @atlas = atlas_surcharge_on
        FROM   dbo.kb_fnt_br_order_validator_v2(
                   @req_date, @date_created, @order_date, @fcuid, @stid, @carrier_name,
                   @packing_basis, NULL, NULL, NULL, @custid, NULL, NULL, @order_no,
                   NULL, @order_type, NULL, NULL, @ccstatus, NULL,
                   @pay, NULL, NULL, NULL, NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL, NULL, NULL,
                   NULL, NULL,
                   NULL, NULL, NULL, NULL,
                   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                   @items, @notes);
        END TRY
        BEGIN CATCH
            -- Mirrors the live rule: the C# catch swallows this and the order SAVES.
            SET @tvf_error = LEFT(ERROR_MESSAGE(), 500);
        END CATCH

        INSERT INTO dbo.asi_validator_baseline
            (order_no, would_run, success_bool, err_code, result_message,
             atlas_surcharge, line_count, qualifying_open,
             credit_plain, credit_rollup, credit_used, credit_ambiguous, tvf_error)
        VALUES (@order_no, 'Y', @sb,
                CASE WHEN @rm LIKE '[[]v2err%]%'
                     THEN LEFT(@rm, CHARINDEX(']', @rm)) END,
                @rm, @atlas, @line_count, @qualifying,
                @cc_plain, @cc_rollup, @ccstatus,
                CASE WHEN ISNULL(@cc_plain,'~') <> ISNULL(@cc_rollup,'~') THEN 'Y' ELSE 'N' END,
                @tvf_error);
    END

    FETCH NEXT FROM cur INTO @order_no;
END

CLOSE cur; DEALLOCATE cur;
SET NOCOUNT OFF;

-- What did we catch?
SELECT would_run, success_bool, err_code, COUNT(*) AS orders
FROM   dbo.asi_validator_baseline
GROUP  BY would_run, success_bool, err_code
ORDER  BY orders DESC;

-- Any order the TVF could not evaluate. Each of these is an order the LIVE rule also
-- fails to validate -- the C# catch swallows the error and the save proceeds. Expect zero
-- now that the @amt_to_pay columns are populated; anything here is a real fail-open
-- population worth reporting.
SELECT tvf_error, COUNT(*) AS orders
FROM   dbo.asi_validator_baseline
WHERE  tvf_error IS NOT NULL
GROUP  BY tvf_error
ORDER  BY orders DESC;

-- How much of this baseline rests on the credit-status guess?
-- Only rows where the two candidates disagree AND the verdict actually turns on credit
-- status (scenarios 1, 5, 6a) are genuinely at risk -- a v2err#2/#3/#4/#7 row is unaffected.
SELECT credit_ambiguous,
       verdict_uses_credit = CASE WHEN err_code IN ('[v2err#1a]','[v2err#1c]','[v2err#5a]','[v2err#6a]')
                                  THEN 'Y' ELSE 'N' END,
       COUNT(*) AS orders
FROM   dbo.asi_validator_baseline
GROUP  BY credit_ambiguous,
          CASE WHEN err_code IN ('[v2err#1a]','[v2err#1c]','[v2err#5a]','[v2err#6a]')
               THEN 'Y' ELSE 'N' END
ORDER  BY credit_ambiguous DESC, orders DESC;
GO


/*--------------------------------------------------------------------------------------
  STEP 4 -- DIFF. Run AFTER deploying asi_Order_Validator to BRR and re-saving the corpus.
  The new rule logs every block to business_rule_log with log_action = 'Validation' and
  return_message = 'order#<no> :: <message>'. Keep the ' :: ' delimiter in step with
  asi_Order_Validator.BlockMessageDelimiter.
--------------------------------------------------------------------------------------*/
;WITH new_side AS (
    SELECT order_no = SUBSTRING(return_message, 7,
                                CHARINDEX(' :: ', return_message) - 7),
           msg      = SUBSTRING(return_message,
                                CHARINDEX(' :: ', return_message) + 4, 4000),
           rn       = ROW_NUMBER() OVER (
                          PARTITION BY SUBSTRING(return_message, 7,
                                                 CHARINDEX(' :: ', return_message) - 7)
                          ORDER BY date_created DESC)
    FROM   business_rule_log
    WHERE  rule_name  = 'asi_Order_Validator'
      AND  log_action = 'Validation'
      AND  CHARINDEX(' :: ', return_message) > 7
)
, diffed AS (
SELECT ISNULL(o.order_no, n.order_no)                       AS order_no,
       o.success_bool                                       AS old_verdict,
       CASE WHEN n.order_no IS NULL THEN 'Y' ELSE 'N' END   AS new_verdict,
       o.err_code                                           AS old_code,
       CASE WHEN n.msg LIKE '[[]v2err%]%'
            THEN LEFT(n.msg, CHARINDEX(']', n.msg)) END     AS new_code,
       o.result_message                                     AS old_message,
       n.msg                                                AS new_message,
       CASE
         WHEN o.would_run = 'N' AND n.order_no IS NULL              THEN 'MATCH (both skipped)'
         WHEN o.success_bool = 'Y' AND n.order_no IS NULL           THEN 'MATCH (both passed)'
         WHEN o.success_bool = 'Y' AND n.order_no IS NOT NULL       THEN '*** NEW BLOCKS, OLD PASSED ***'
         WHEN o.success_bool = 'N' AND n.order_no IS NULL           THEN '*** OLD BLOCKED, NEW PASSED ***'
         -- em-dash: OLD is VARCHAR-mangled, NEW is not. Expected, documented diff.
         WHEN REPLACE(o.result_message, CHAR(151), '-') = REPLACE(n.msg, N'—', '-')
                                                                    THEN 'MATCH'
         WHEN LEFT(o.result_message, CHARINDEX(']', o.result_message))
            = LEFT(n.msg, CHARINDEX(']', n.msg))                    THEN 'same code, TEXT DIFFERS'
         ELSE '*** DIFFERENT ***'
       END                                                  AS result
FROM        dbo.asi_validator_baseline o
FULL JOIN   (SELECT * FROM new_side WHERE rn = 1) n ON n.order_no = o.order_no
)
SELECT order_no, old_verdict, new_verdict, old_code, new_code,
       old_message, new_message, result
FROM   diffed
ORDER  BY CASE WHEN result LIKE '***%' THEN 0 ELSE 1 END, order_no;
GO


/*--------------------------------------------------------------------------------------
  STEP 5 -- CLEANUP
--------------------------------------------------------------------------------------*/
-- DROP TABLE dbo.asi_validator_baseline;
-- DELETE FROM business_rule_log WHERE rule_name = 'asi_Order_Validator' AND log_action = 'Validation';
