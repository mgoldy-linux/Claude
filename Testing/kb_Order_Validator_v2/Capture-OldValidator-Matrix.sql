/*======================================================================================
  Capture-OldValidator-Matrix.sql
  Synthetic scenario matrix -- authoritative OLD output for EVERY validator path.

  WHY THIS EXISTS
    Capture-OldValidator-Baseline.sql samples real saved orders, and that sampling is
    structurally biased: the validator BLOCKS saves, so an order that fails it never gets
    persisted. A 500-order corpus yielded 385 passes, 114 skips and exactly ONE block --
    eight of the nine checks had no coverage at all.

    Calling kb_fnt_br_order_validator_v2 directly means we do not need a real order. This
    script feeds it CONSTRUCTED parameter sets chosen so each check fires, plus near-miss
    cases that must NOT fire. That is the positive test the corpus cannot provide.

  THE TWO TESTS ARE COMPLEMENTARY -- run both:
    Baseline.sql  -> proves the PLUMBING (DataWindow fields, reference queries, joins)
                     and that the port does not spuriously block 385 passing orders.
    Matrix.sql    -> proves the LOGIC   (all nine checks fire under the same conditions).

  NEW SIDE: asi_Order_Validator.Validate() takes a plain OrderSnapshot + ReferenceData
  with no P21 dependency, so a console harness can construct the same inputs and diff
  verdict + message text against the expected_code column here.

  Run in P21BusinessRules. Read-only apart from its own scratch table.
======================================================================================*/


/*--------------------------------------------------------------------------------------
  STEP 0 -- DISCOVER SEED VALUES.
  The TVF's derived variables (@wc, @default_carrier, @freight_auto_adds, @order_total)
  come from live lookups, so the matrix needs real carriers / ship-tos / freight codes /
  items. This finds them and FAILS LOUDLY if the environment cannot supply one.
--------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#seed') IS NOT NULL DROP TABLE #seed;
CREATE TABLE #seed (k VARCHAR(30) PRIMARY KEY, v VARCHAR(255), note VARCHAR(200));

-- A will-call carrier and a non-will-call carrier (kb_view_carrier = p21_view_address +
-- address_ud where carrier_flag='Y'). @wc is looked up BY NAME, so names must be unique.
INSERT #seed
SELECT TOP 1 'WC_CARRIER', a.name, 'address_ud.will_call = Y'
FROM   p21_view_address a JOIN address_ud ud ON ud.id = a.id
WHERE  a.carrier_flag = 'Y' AND ud.will_call = 'Y' AND a.delete_flag = 'N'
  AND  a.name NOT IN (SELECT name FROM p21_view_address WHERE carrier_flag='Y'
                      GROUP BY name HAVING COUNT(*) > 1)
ORDER BY a.id;

INSERT #seed
SELECT TOP 1 'NONWC_CARRIER', a.name, 'will_call N or absent'
FROM   p21_view_address a LEFT JOIN address_ud ud ON ud.id = a.id
WHERE  a.carrier_flag = 'Y' AND COALESCE(ud.will_call,'N') = 'N' AND a.delete_flag = 'N'
  AND  a.name NOT IN (SELECT name FROM p21_view_address WHERE carrier_flag='Y'
                      GROUP BY name HAVING COUNT(*) > 1)
ORDER BY a.id;

-- A live ship-to. Its default carrier must differ from NONWC_CARRIER so the @freight_message
-- "different carrier" branch is exercised rather than the "same carrier" one.
INSERT #seed
SELECT TOP 1 'SHIP_TO', CAST(st.ship_to_id AS VARCHAR(255)), 'delete_flag N'
FROM   p21_view_ship_to st
WHERE  st.delete_flag = 'N' AND st.default_carrier_id IS NOT NULL
ORDER BY st.ship_to_id;

-- Freight codes. AUTOADD drives scenarios 1 and 2; NOAUTO must avoid every code the
-- checks special-case (5,6,7,8,10,12) so it reaches scenarios 6 and 7.
INSERT #seed
SELECT TOP 1 'FC_AUTOADD', CAST(freight_code_uid AS VARCHAR(255)),
       'outgoing_freight = Y: ' + ISNULL(freight_desc,'')
FROM   p21_view_freight_code
WHERE  row_status = 704 AND ISNULL(outgoing_freight,'N') = 'Y'
ORDER BY freight_code_uid;

INSERT #seed
SELECT TOP 1 'FC_NOAUTO', CAST(freight_code_uid AS VARCHAR(255)),
       'outgoing_freight = N, not 5/6/7/8/10/12: ' + ISNULL(freight_desc,'')
FROM   p21_view_freight_code
WHERE  row_status = 704 AND ISNULL(outgoing_freight,'N') = 'N'
  AND  freight_code_uid NOT IN (5,6,7,8,10,12)
ORDER BY freight_code_uid;

-- A stock item that COUNTS toward @order_total / @items_open: present in the
-- classification view with a product group that is not OCHARGE.
INSERT #seed
SELECT TOP 1 'STOCK_ITEM', ic.item_id, 'product_group_id = ' + ISNULL(ic.product_group_id,'')
FROM   kb_view_item_classifications_loc100 ic
WHERE  ic.product_group_id IS NOT NULL AND ic.product_group_id NOT IN ('OCHARGE')
  AND  ic.item_id IS NOT NULL AND LEN(ic.item_id) > 0
ORDER BY ic.item_id;

-- ---- Seeds for the two UNTESTED branches of @freight_message ----------------------
-- @freight_message has three branches, and only the third (carrier <> default carrier)
-- was reachable with the seeds above. The other two require @carrier_name to EQUAL the
-- ship-to's default carrier, and they matter disproportionately: the first one is the
-- ONLY caller of dbo.kb_fn_number_shorten, which the C# port reimplements by hand
-- (away-from-zero rounding, K/M/B abbreviation, '$' insertion for negatives).
--
-- FREIGHT ship-to: default carrier is not will-call AND kb_fnt_br_shipto_info returns a
-- NON-ZERO val_freight  -> branch 1, 'price <shortened> each'.
INSERT #seed
SELECT TOP 1 'ST_FREIGHT', CAST(st.ship_to_id AS VARCHAR(255)),
       'val_freight = ' + CAST(fc.val_freight AS VARCHAR(40)) + ', default carrier = ' + a.name
FROM   p21_view_ship_to st
JOIN   p21_view_address a ON a.id = st.default_carrier_id AND a.carrier_flag = 'Y'
LEFT   JOIN address_ud ud ON ud.id = a.id
CROSS  APPLY dbo.kb_fnt_br_shipto_info(st.ship_to_id) fc
WHERE  st.delete_flag = 'N' AND COALESCE(ud.will_call,'N') = 'N'
  AND  ISNULL(fc.val_freight,0) <> 0
  AND  a.name NOT IN (SELECT name FROM p21_view_address WHERE carrier_flag='Y'
                      GROUP BY name HAVING COUNT(*) > 1)
ORDER BY st.ship_to_id;

INSERT #seed
SELECT TOP 1 'ST_FREIGHT_CAR', a.name, 'default carrier of ST_FREIGHT'
FROM   p21_view_ship_to st
JOIN   p21_view_address a ON a.id = st.default_carrier_id AND a.carrier_flag = 'Y'
WHERE  st.ship_to_id = (SELECT CAST(v AS DECIMAL(19,0)) FROM #seed WHERE k='ST_FREIGHT');

-- ZERO ship-to: default carrier not will-call, val_freight is zero/absent -> branch 2,
-- the 'ask Susan to set the default Freight Charge' message.
INSERT #seed
SELECT TOP 1 'ST_ZERO', CAST(st.ship_to_id AS VARCHAR(255)),
       'val_freight = 0/absent, default carrier = ' + a.name
FROM   p21_view_ship_to st
JOIN   p21_view_address a ON a.id = st.default_carrier_id AND a.carrier_flag = 'Y'
LEFT   JOIN address_ud ud ON ud.id = a.id
OUTER  APPLY dbo.kb_fnt_br_shipto_info(st.ship_to_id) fc
WHERE  st.delete_flag = 'N' AND COALESCE(ud.will_call,'N') = 'N'
  AND  ISNULL(fc.val_freight,0) = 0
  AND  a.name NOT IN (SELECT name FROM p21_view_address WHERE carrier_flag='Y'
                      GROUP BY name HAVING COUNT(*) > 1)
ORDER BY st.ship_to_id;

INSERT #seed
SELECT TOP 1 'ST_ZERO_CAR', a.name, 'default carrier of ST_ZERO'
FROM   p21_view_ship_to st
JOIN   p21_view_address a ON a.id = st.default_carrier_id AND a.carrier_flag = 'Y'
WHERE  st.ship_to_id = (SELECT CAST(v AS DECIMAL(19,0)) FROM #seed WHERE k='ST_ZERO');

SELECT * FROM #seed ORDER BY k;

-- SAVE THIS OUTPUT. The expected message text embeds these values verbatim (freight code
-- description, carrier names, default carrier name), so the C# comparison harness must run
-- against the SAME seeds to produce byte-identical strings.
IF (SELECT COUNT(*) FROM #seed) < 10
BEGIN
    RAISERROR('SEED DISCOVERY INCOMPLETE -- expected 10 seeds. Cases 12/13 (the kb_fn_number_shorten branches) need ST_FREIGHT/ST_ZERO and their carriers; if those are missing, drop cases 12-13 rather than running them against NULLs.', 16, 1);
END
GO


/*--------------------------------------------------------------------------------------
  STEP 1 -- SCENARIO DEFINITIONS.
  One row per case. The first block targets each check; the second block is near-misses
  that must NOT fire (boundary + exemption coverage).

  Column meanings:
    carrier_kind    'WC' | 'NONWC'      -> which seed carrier, i.e. drives @wc
    fc_kind         'AUTOADD'|'NOAUTO'|'6'|'8'|'12'  -> @freight_code_uid
    freight_amt     extended_price on the FREIGHT CHARGE line (NULL = no freight line)
    freight_open    qty_open on that line
    stock_amt       extended_price on the stock line (NULL = no stock line)
    stock_open      qty_open on that line
    req_date        '2049-12-31' makes @order_status = 'Will Advise'
--------------------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#scn') IS NOT NULL DROP TABLE #scn;
CREATE TABLE #scn (
    id INT PRIMARY KEY, descr VARCHAR(120), expected_code VARCHAR(20),
    credit VARCHAR(8), fc_kind VARCHAR(10), packing VARCHAR(16), carrier_kind VARCHAR(10),
    req_date DATETIME, order_type VARCHAR(255),
    freight_amt DECIMAL(19,4), freight_open DECIMAL(19,4),
    stock_amt DECIMAL(19,4), stock_open DECIMAL(19,4),
    freight_note VARCHAR(1), sig_note VARCHAR(1)
);

INSERT #scn VALUES
-- ===== POSITIVE: each check must fire =====
 (1 ,'S1a auto-freight + COD, freight added manually','[v2err#1a]','COD','AUTOADD','Order Complete','NONWC','2026-06-01','OE',  50.00, 1,  100.00, 1,'N','N')
,(2 ,'S1c auto-freight + COD, no freight item'       ,'[v2err#1c]','COD','AUTOADD','Order Complete','NONWC','2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(3 ,'S2a auto-freight + freight present + Order Cmp','[v2err#2a]','NORMAL','AUTOADD','Order Complete','NONWC','2026-06-01','OE',  50.00, 1,  100.00, 1,'N','N')
,(4 ,'S2b auto-freight + freight OPEN + partial'     ,'[v2err#2b]','NORMAL','AUTOADD','Item Complete' ,'NONWC','2026-06-01','OE',  50.00, 1,  100.00, 1,'N','N')
,(5 ,'S3a prepaid(6) + no freight item + Order Cmp'  ,'[v2err#3a]','NORMAL','6'      ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(6 ,'S3b prepaid(6) + no OPEN freight + items open' ,'[v2err#3b]','NORMAL','6'      ,'Item Complete' ,'NONWC','2026-06-01','OE',  50.00, 0,  100.00, 1,'N','N')
,(7 ,'S4a will-call code(8) + non-will-call carrier' ,'[v2err#4a]','NORMAL','8'      ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(8 ,'S4c will-call carrier + non-will-call code'    ,'[v2err#4c]','NORMAL','NOAUTO' ,'Order Complete','WC'   ,'2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(9 ,'S6a COD + zero freight + not Will Advise'      ,'[v2err#6a]','COD'   ,'NOAUTO' ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(10,'S6b Will Advise + freight now non-zero + note' ,'[v2err#6b]','NORMAL','NOAUTO' ,'Order Complete','NONWC','2049-12-31','OE',  50.00, 1,  100.00, 1,'Y','N')
,(11,'S7 order over $15k with no signature note'     ,'[v2err#7]' ,'NORMAL','NOAUTO' ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,16000.00, 1,'N','N')

-- The two @freight_message branches the seeds above could not reach. Both require
-- @carrier_name = the ship-to's OWN default carrier. Case 12 is the only path that calls
-- dbo.kb_fn_number_shorten -- expect 'price $<abbreviated> each' in the message, and diff
-- that literal against the C# NumberShorten() port.
,(12,'S3a w/ default carrier + NON-ZERO freight charge','[v2err#3a]','NORMAL','6','Order Complete','STF_DEF','2026-06-01','OE',NULL,0,100.00,1,'N','N')
,(13,'S3a w/ default carrier + ZERO freight charge'    ,'[v2err#3a]','NORMAL','6','Order Complete','STZ_DEF','2026-06-01','OE',NULL,0,100.00,1,'N','N')

-- ===== NEGATIVE: near-misses that must NOT fire (expected_code NULL = save allowed) =====
,(20,'clean order, nothing wrong'                    ,NULL,'NORMAL','NOAUTO' ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(21,'S7 boundary: 14999.99 is under the threshold'  ,NULL,'NORMAL','NOAUTO' ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,14999.99, 1,'N','N')
,(22,'S7 exempt: CUO Entry consignment order'        ,NULL,'NORMAL','NOAUTO' ,'Order Complete','NONWC','2026-06-01','CUO Entry',NULL,0,16000.00,1,'N','N')
,(23,'S7 satisfied: signature note present'          ,NULL,'NORMAL','NOAUTO' ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,16000.00, 1,'N','Y')
,(24,'S6a exempt: freight code 12 (THIRD)'           ,NULL,'COD'   ,'12'     ,'Order Complete','NONWC','2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(25,'S4c allowed: will-call carrier + code 12'      ,NULL,'NORMAL','12'     ,'Order Complete','WC'   ,'2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
,(26,'S6a satisfied: freight is non-zero'            ,NULL,'COD'   ,'NOAUTO' ,'Order Complete','NONWC','2026-06-01','OE',  50.00, 1,  100.00, 1,'N','N')
,(27,'S6b not met: Will Advise but no freight note'  ,NULL,'NORMAL','NOAUTO' ,'Order Complete','NONWC','2049-12-31','OE',  50.00, 1,  100.00, 1,'N','N')
-- Case 28 originally duplicated case 9's inputs, so 6a fired and it read as a failure.
-- Non-zero freight now isolates it: 1-4 skipped (NOAUTO, fc<>6/8, wc=N), 6a skipped
-- (freight_zero='N'), 6b skipped (not Will Advise), 7 skipped (under $15k). Only S5 sits
-- in that gap.
-- HONEST CAVEAT: passing here does NOT prove S5 is unreachable. S5 also needs a 'SURCHARG'
-- ship-to class, a fuel-surcharge-flagged item and a non-employee customer -- customer
-- 12345 does not exist, so kb_view_customer returns NULL and condition (d) fails on its
-- own. S5's unreachability is proven by INSPECTION instead, and that proof is airtight:
-- @a_schg_on is a literal 'Y' never reassigned, and @fuel_message's outer
-- CASE WHEN @a_schg_on='Y' THEN '' makes it unconditionally empty.
,(28,'S5 gap case -- nothing should fire here'        ,NULL,'COD'  ,'NOAUTO' ,'Order Complete','NONWC','2026-06-01','OE',  50.00, 1,  100.00, 1,'N','N')
,(29,'pre-2018 order: always allowed'                ,NULL,'COD'   ,'AUTOADD','Order Complete','NONWC','2026-06-01','OE',   NULL, 0,  100.00, 1,'N','N')
;
-- Scenario 29 is given a pre-epoch date_created in STEP 2 (all others use 2026-01-01).
GO


/*--------------------------------------------------------------------------------------
  STEP 2 -- RUN THE MATRIX
--------------------------------------------------------------------------------------*/
IF OBJECT_ID('dbo.asi_validator_matrix') IS NOT NULL DROP TABLE dbo.asi_validator_matrix;
CREATE TABLE dbo.asi_validator_matrix (
    id INT PRIMARY KEY, descr VARCHAR(120),
    expected_code VARCHAR(20) NULL, actual_code VARCHAR(20) NULL,
    success_bool VARCHAR(1) NULL, result_message VARCHAR(4000) NULL,
    atlas_surcharge VARCHAR(1) NULL, tvf_error VARCHAR(500) NULL,
    verdict VARCHAR(30) NULL, captured_at DATETIME NOT NULL DEFAULT(GETDATE())
);

SET NOCOUNT ON;

DECLARE @wc_car   VARCHAR(255) = (SELECT v FROM #seed WHERE k='WC_CARRIER'),
        @nwc_car  VARCHAR(255) = (SELECT v FROM #seed WHERE k='NONWC_CARRIER'),
        @shipto   DECIMAL(19,0)= (SELECT CAST(v AS DECIMAL(19,0)) FROM #seed WHERE k='SHIP_TO'),
        @fc_auto  INT          = (SELECT CAST(v AS INT) FROM #seed WHERE k='FC_AUTOADD'),
        @fc_noaut INT          = (SELECT CAST(v AS INT) FROM #seed WHERE k='FC_NOAUTO'),
        @item     VARCHAR(40)  = (SELECT v FROM #seed WHERE k='STOCK_ITEM'),
        @st_frt   DECIMAL(19,0)= (SELECT CAST(v AS DECIMAL(19,0)) FROM #seed WHERE k='ST_FREIGHT'),
        @st_frtc  VARCHAR(255) = (SELECT v FROM #seed WHERE k='ST_FREIGHT_CAR'),
        @st_zero  DECIMAL(19,0)= (SELECT CAST(v AS DECIMAL(19,0)) FROM #seed WHERE k='ST_ZERO'),
        @st_zeroc VARCHAR(255) = (SELECT v FROM #seed WHERE k='ST_ZERO_CAR');

DECLARE @id INT, @descr VARCHAR(120), @exp VARCHAR(20),
        -- @ck MUST be at least VARCHAR(10) to match #scn.carrier_kind. It was VARCHAR(6),
        -- which silently truncated 'STF_DEF'/'STZ_DEF' to 6 chars so the CASE below fell to
        -- ELSE -- cases 12/13 then duplicated case 5, still returned the expected code, and
        -- reported PASS while testing nothing.
        @credit VARCHAR(8), @fck VARCHAR(10), @packing VARCHAR(16), @ck VARCHAR(10),
        @req DATETIME, @otype VARCHAR(255),
        @famt DECIMAL(19,4), @fopen DECIMAL(19,4),
        @samt DECIMAL(19,4), @sopen DECIMAL(19,4),
        @fnote VARCHAR(1), @snote VARCHAR(1),
        @carrier VARCHAR(255), @fcuid INT, @created DATETIME, @st DECIMAL(19,0),
        @sb VARCHAR(1), @rm VARCHAR(4000), @atlas VARCHAR(1), @err VARCHAR(500);

DECLARE @items dbo.kb_TableTypeItemsOnOrder;
DECLARE @notes dbo.kb_TableTypeFourStrings;
DECLARE @pay   dbo.kb_TableTypeFourStrings;   -- always empty (@cc_used is dead code)

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT id,descr,expected_code,credit,fc_kind,packing,carrier_kind,req_date,order_type,
           freight_amt,freight_open,stock_amt,stock_open,freight_note,sig_note
    FROM #scn ORDER BY id;
OPEN c;
FETCH NEXT FROM c INTO @id,@descr,@exp,@credit,@fck,@packing,@ck,@req,@otype,
                       @famt,@fopen,@samt,@sopen,@fnote,@snote;

WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM @items; DELETE FROM @notes;
    SET @sb=NULL; SET @rm=NULL; SET @atlas=NULL; SET @err=NULL;

    -- 'STF_DEF'/'STZ_DEF' select BOTH a ship-to and its own default carrier, so that
    -- @carrier_name = @default_carrier and the first two @freight_message branches become
    -- reachable. Everything else uses the generic seeds.
    SET @carrier = CASE @ck WHEN 'WC'      THEN @wc_car
                            WHEN 'STF_DEF' THEN @st_frtc
                            WHEN 'STZ_DEF' THEN @st_zeroc
                            ELSE @nwc_car END;
    SET @st      = CASE @ck WHEN 'STF_DEF' THEN @st_frt
                            WHEN 'STZ_DEF' THEN @st_zero
                            ELSE @shipto END;
    SET @fcuid   = CASE @fck WHEN 'AUTOADD' THEN @fc_auto
                             WHEN 'NOAUTO'  THEN @fc_noaut
                             ELSE CAST(@fck AS INT) END;
    -- Scenario 29 exercises the pre-2018-07-23 "always allow" gate.
    SET @created = CASE WHEN @id = 29 THEN '2018-01-01' ELSE '2026-01-01' END;

    -- Freight line. pricing_unit_size MUST be non-zero: @amt_to_pay (TVF line 312) divides
    -- by it, and its ISNULL(...,0.00001) guard is defeated by the decimal(19,4) conversion.
    IF @famt IS NOT NULL
        INSERT INTO @items (item_id, qty_open, extended_price,
                            qty_allocated_uom, unit_size, unit_price, pricing_unit_size)
        VALUES ('FREIGHT CHARGE', @fopen, @famt, 0, 1, @famt, 1);

    -- Stock line -- the one that counts toward @order_total and @items_open.
    IF @samt IS NOT NULL
        INSERT INTO @items (item_id, qty_open, extended_price,
                            qty_allocated_uom, unit_size, unit_price, pricing_unit_size)
        VALUES (@item, @sopen, @samt, 0, 1, @samt, 1);

    -- Notes: s1 = topic, s2 = notepad_class_id, s3 = mandatory, s4 = note (positional).
    IF @fnote = 'Y' INSERT INTO @notes (s1,s2,s3,s4) VALUES ('Freight Quote Required',NULL,'Y','synthetic');
    IF @snote = 'Y' INSERT INTO @notes (s1,s2,s3,s4) VALUES ('Signature Required',NULL,'Y','synthetic');

    BEGIN TRY
        SELECT @sb = success_bool, @rm = result_message, @atlas = atlas_surcharge_on
        FROM   dbo.kb_fnt_br_order_validator_v2(
                   @req, @created, '2026-01-01', @fcuid, @st, @carrier,
                   @packing, NULL, NULL, NULL, 12345, NULL, NULL, 'SYNTH',
                   NULL, @otype, NULL, NULL, @credit, NULL,
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
        SET @err = LEFT(ERROR_MESSAGE(), 500);
    END CATCH

    INSERT dbo.asi_validator_matrix
        (id, descr, expected_code, actual_code, success_bool, result_message,
         atlas_surcharge, tvf_error, verdict)
    SELECT @id, @descr, @exp,
           CASE WHEN @rm LIKE '[[]v2err%]%' THEN LEFT(@rm, CHARINDEX(']', @rm)) END,
           @sb, @rm, @atlas, @err,
           CASE
             WHEN @err IS NOT NULL THEN '*** TVF ERROR ***'
             WHEN @exp IS NULL AND @sb = 'Y' THEN 'PASS (correctly allowed)'
             WHEN @exp IS NULL AND @sb <> 'Y' THEN '*** UNEXPECTED BLOCK ***'
             WHEN @exp IS NOT NULL AND @rm LIKE '[[]v2err%]%'
                  AND LEFT(@rm, CHARINDEX(']', @rm)) = @exp THEN 'PASS (fired as expected)'
             WHEN @exp IS NOT NULL AND @sb = 'Y' THEN '*** DID NOT FIRE ***'
             ELSE '*** WRONG CHECK FIRED ***'
           END;

    FETCH NEXT FROM c INTO @id,@descr,@exp,@credit,@fck,@packing,@ck,@req,@otype,
                           @famt,@fopen,@samt,@sopen,@fnote,@snote;
END
CLOSE c; DEALLOCATE c;
SET NOCOUNT OFF;
GO


/*--------------------------------------------------------------------------------------
  STEP 3 -- RESULTS.

  READ THIS BEFORE ASSUMING A FAILURE IS A BUG. A '*** DID NOT FIRE ***' can mean either
  (a) the scenario row does not actually satisfy that check's conditions in THIS
      environment -- most likely the seed freight code does not behave as assumed, or an
      earlier check in the if/else chain matched first and short-circuited; or
  (b) a genuine discovery about the rule.
  Check actual_code first: if a DIFFERENT check fired, the chain short-circuited and the
  scenario row needs tightening, not the rule.
--------------------------------------------------------------------------------------*/
SELECT id, descr, expected_code, actual_code, success_bool, verdict,
       LEFT(result_message, 160) AS message_head
FROM   dbo.asi_validator_matrix
ORDER  BY CASE WHEN verdict LIKE '***%' THEN 0 ELSE 1 END, id;

SELECT verdict, COUNT(*) AS cases
FROM   dbo.asi_validator_matrix
GROUP  BY verdict ORDER BY cases DESC;

-- Full message text for the fired checks -- this is the string the C# port must reproduce
-- character for character (modulo the two documented intentional diffs: em-dash rendering
-- and \r\n handling).
SELECT id, expected_code, result_message
FROM   dbo.asi_validator_matrix
WHERE  result_message IS NOT NULL
ORDER  BY id;
GO


/*--------------------------------------------------------------------------------------
  STEP 3b -- kb_fn_number_shorten REFERENCE TABLE.

  Case 12 only reaches this function with one ship-to's freight charge, which exercises a
  single trivial branch. It is a PURE function, so testing it through the validator is the
  wrong shape -- drive it directly instead and assert the C# NumberShorten() port against
  these outputs.

  Covers every branch and the boundaries between them. Two traps the port has to get right:
    - T-SQL ROUND() is half-away-from-zero; .NET Math.Round defaults to BANKER'S rounding.
    - The '$' goes AFTER the minus sign for negatives (STUFF(v,2,0,'$')), not before.
  The thresholds are all strict > so the exact boundary values (1000, 10000, ...) fall to
  the branch BELOW -- hence the pairs either side of each.
--------------------------------------------------------------------------------------*/
;WITH v(n) AS (SELECT * FROM (VALUES
      (0.0),(1.0),(1.5),(99.99),(100.0),(100.01),(110.0),(999.99),
      (1000.0),(1000.01),(1500.0),(1550.0),(9999.99),
      (10000.0),(10000.01),(15000.0),(15500.0),(999999.99),
      (1000000.0),(1000000.01),(1500000.0),(10000000.01),(15000000.0),
      (1000000000.01),(1500000000.0),(10000000000.01),(15000000000.0),
      (-1.5),(-110.0),(-1500.0),(-15000.0),(-1500000.0)
   ) t(n))
SELECT input_value  = n,
       dollars_off  = dbo.kb_fn_number_shorten(n, NULL),
       dollars_on   = dbo.kb_fn_number_shorten(n, 1)
FROM   v
ORDER  BY n;
GO


/*--------------------------------------------------------------------------------------
  STEP 4 -- CLEANUP
--------------------------------------------------------------------------------------*/
-- DROP TABLE dbo.asi_validator_matrix;
