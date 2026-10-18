/*
SA 56290 - PLAY test: cancel 2 expired quotes (past the 90-day window), leave 1 alone (inside the window), then try to reopen the 2 in Order Entry and set a new expiration date.
DRAFT - NOT RUN. Run in SSMS against P21Play (NOT Prod).
"Cancel" = what the earlier Research-Cancel-Quotes3.sql test used: oe_hdr.cancel_flag='Y' + completed='Y',
plus the child flags (oe_line.complete, quote_hdr.complete_flag, quote_line.line_complete_flag).
Not written: the lost_sales_transaction row the UI adds for the cancel reason code (see Research-Cancel-Quotes3.sql lines 53-60).
If the UI "reopen" depends on that row, that's a finding -- tell me.
*/

-- ============================================================
-- STEP 1: pick the 3 quotes (read-only). 2 = past the 90-day window (CANCEL these, what the job would take),
--         1 = expired but still INSIDE 90 days (SKIP -- control, the job would leave it alone).
-- ============================================================
;WITH q AS (
    SELECT oh.order_no, oh.oe_hdr_uid, oh.customer_id, qh.expiration_date,
           DATEDIFF(DAY, qh.expiration_date, CAST(GETDATE() AS date)) AS days_past_expiration,
           (SELECT COUNT(*) FROM oe_line ol WHERE ol.order_no = oh.order_no) AS line_count
    FROM oe_hdr oh
    JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid
    WHERE oh.projected_order = 'Y'
      AND ISNULL(oh.completed,'N')   <> 'Y'
      AND ISNULL(oh.cancel_flag,'N') <> 'Y'
      AND oh.delete_flag = 'N'
      AND qh.expiration_date < CAST(GETDATE() AS date)
)
SELECT 'CANCEL - over 90' AS bucket, * FROM (SELECT TOP 2 * FROM q WHERE days_past_expiration > 90 AND line_count BETWEEN 1 AND 5 ORDER BY days_past_expiration) a
UNION ALL
SELECT 'SKIP - inside 90',  * FROM (SELECT TOP 1 * FROM q WHERE days_past_expiration BETWEEN 1 AND 90 AND line_count BETWEEN 1 AND 5 ORDER BY days_past_expiration DESC) b;
-- Copy ONLY the 2 CANCEL order_no values into @orders below (varchar(8)). Note the SKIP one for the after-check.
GO

-- ============================================================
-- STEP 2: backup + cancel. @Commit = 0 (as set) COMMITS; set to 1 for a dry run that ROLLS BACK.
-- ============================================================
DECLARE @Commit bit = 0;
DECLARE @orders TABLE (order_no varchar(8) PRIMARY KEY);
INSERT @orders VALUES ('XXXXXXXX'), ('XXXXXXXX');   -- <-- the 2 CANCEL order_no values from Step 1 (NOT the skipped one)

IF (SELECT COUNT(*) FROM @orders o JOIN oe_hdr oh ON oh.order_no = o.order_no AND oh.projected_order = 'Y') <> 2
BEGIN RAISERROR('Expected exactly 2 existing quotes -- check @orders', 16, 1); RETURN; END

BEGIN TRAN;

-- before-state, kept for reopen/undo
IF OBJECT_ID('dbo.asi_bak_SA56290_cancel_test') IS NULL
    CREATE TABLE dbo.asi_bak_SA56290_cancel_test (
        tbl varchar(12), uid int, order_no varchar(8), flag1 varchar(10), flag2 varchar(10), saved datetime DEFAULT GETDATE());

INSERT dbo.asi_bak_SA56290_cancel_test (tbl, uid, order_no, flag1, flag2)
SELECT 'oe_hdr', oh.oe_hdr_uid, oh.order_no, oh.cancel_flag, oh.completed FROM oe_hdr oh JOIN @orders o ON o.order_no = oh.order_no
UNION ALL SELECT 'oe_line', ol.oe_line_uid, ol.order_no, ol.complete, NULL FROM oe_line ol JOIN @orders o ON o.order_no = ol.order_no
UNION ALL SELECT 'quote_hdr', qh.oe_hdr_uid, oh.order_no, qh.complete_flag, NULL FROM quote_hdr qh JOIN oe_hdr oh ON oh.oe_hdr_uid = qh.oe_hdr_uid JOIN @orders o ON o.order_no = oh.order_no
UNION ALL SELECT 'quote_line', ql.oe_line_uid, ol.order_no, ql.line_complete_flag, NULL FROM quote_line ql JOIN oe_line ol ON ol.oe_line_uid = ql.oe_line_uid JOIN @orders o ON o.order_no = ol.order_no;

UPDATE ol SET complete = 'Y', qty_allocated = 0, disposition = '', date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = SUSER_SNAME()
FROM oe_line ol JOIN @orders o ON o.order_no = ol.order_no;

UPDATE ql SET line_complete_flag = 'Y'
FROM quote_line ql JOIN oe_line ol ON ol.oe_line_uid = ql.oe_line_uid JOIN @orders o ON o.order_no = ol.order_no;

UPDATE qh SET complete_flag = 'Y'
FROM quote_hdr qh JOIN oe_hdr oh ON oh.oe_hdr_uid = qh.oe_hdr_uid JOIN @orders o ON o.order_no = oh.order_no;

UPDATE oh SET cancel_flag = 'Y', completed = 'Y', date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = SUSER_SNAME()
FROM oe_hdr oh JOIN @orders o ON o.order_no = oh.order_no;

-- after-state
SELECT oh.order_no, oh.cancel_flag, oh.completed, qh.complete_flag, qh.expiration_date,
       (SELECT COUNT(*) FROM oe_line ol WHERE ol.order_no = oh.order_no AND ol.complete = 'Y') AS lines_complete,
       (SELECT COUNT(*) FROM oe_line ol WHERE ol.order_no = oh.order_no) AS lines_total
FROM oe_hdr oh JOIN @orders o ON o.order_no = oh.order_no LEFT JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid;

IF @Commit = 0 COMMIT; ELSE ROLLBACK;
PRINT CASE WHEN @Commit = 0 THEN 'COMMITTED' ELSE 'ROLLED BACK (set @Commit = 0 to keep)' END;
GO
-- Note: RCSI is ON -- a SELECT from another session before COMMIT shows the OLD values.

-- ============================================================
-- STEP 3 (only if the UI reopen fails): restore from the backup table
-- ============================================================
-- UPDATE oh SET cancel_flag = b.flag1, completed = b.flag2 FROM oe_hdr oh JOIN dbo.asi_bak_SA56290_cancel_test b ON b.tbl='oe_hdr' AND b.uid = oh.oe_hdr_uid;
-- UPDATE ol SET complete = b.flag1 FROM oe_line ol JOIN dbo.asi_bak_SA56290_cancel_test b ON b.tbl='oe_line' AND b.uid = ol.oe_line_uid;
-- UPDATE qh SET complete_flag = b.flag1 FROM quote_hdr qh JOIN dbo.asi_bak_SA56290_cancel_test b ON b.tbl='quote_hdr' AND b.uid = qh.oe_hdr_uid;
-- UPDATE ql SET line_complete_flag = b.flag1 FROM quote_line ql JOIN dbo.asi_bak_SA56290_cancel_test b ON b.tbl='quote_line' AND b.uid = ql.oe_line_uid;
-- (qty_allocated / disposition on oe_line are NOT in the backup -- Step 2 zeroes them; fine for quotes, flag if reopen shows odd allocation.)
