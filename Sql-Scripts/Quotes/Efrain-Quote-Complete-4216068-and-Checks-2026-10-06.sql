-- Efrain Reyes (EREYES) - complete projected order/quote 4216068 + read-only checks (2026-10-06)
-- No ticket. Reviewed Efrain's 4 UPDATEs: fixed missing ")" on the quote_line update, wrapped in a
-- transaction with @@ROWCOUNT PRINTs, uppercase user ID. Run Play first. Nothing here has been run.
-- Column names taken from Efrain's script / Work-Log; NOT verified against the schema
-- (order_date, line_no, qty_ordered in section 3 are the least certain).
-- These are quotes (projected_order = 'Y'), so allocation is not expected - section 3 just proves it.

------------------------------------------------------------------------------------------
-- 1) Read-only: state of 5 quotes (oe_hdr / quote_hdr / oe_line / quote_line)
------------------------------------------------------------------------------------------
SELECT h.order_no,
       h.projected_order,
       h.completed                                                  AS hdr_completed,
       q.complete_flag                                              AS quote_hdr_complete,
       COUNT(l.oe_line_uid)                                         AS lines,
       SUM(CASE WHEN l.complete = 'Y' THEN 1 ELSE 0 END)            AS lines_complete,
       SUM(CASE WHEN l.qty_allocated > 0 THEN 1 ELSE 0 END)         AS lines_allocated,
       SUM(CASE WHEN ql.line_complete_flag = 'Y' THEN 1 ELSE 0 END) AS quote_lines_complete,
       h.date_last_modified,
       h.last_maintained_by
FROM oe_hdr h
LEFT JOIN quote_hdr  q  ON q.oe_hdr_uid  = h.oe_hdr_uid
LEFT JOIN oe_line    l  ON l.order_no     = h.order_no
LEFT JOIN quote_line ql ON ql.oe_line_uid = l.oe_line_uid
WHERE h.order_no IN ('4222245','3654565','4008353','2699382','3840866')
GROUP BY h.order_no, h.projected_order, h.completed, q.complete_flag,
         h.date_last_modified, h.last_maintained_by
ORDER BY h.order_no;

------------------------------------------------------------------------------------------
-- 2) Update for order 4216068 - transaction is left OPEN on purpose.
--    Check the PRINTed counts (expect 1 header, N lines), then COMMIT TRAN; or ROLLBACK TRAN;
------------------------------------------------------------------------------------------
/*
BEGIN TRAN;

SELECT 'oe_line' t, COUNT(*) n, SUM(CASE WHEN l.qty_allocated > 0 THEN 1 ELSE 0 END) allocated
FROM oe_line l JOIN oe_hdr h ON h.order_no = l.order_no
WHERE h.projected_order = 'Y' AND l.order_no = '4216068'
  AND (l.complete <> 'Y' OR l.complete IS NULL);

UPDATE l SET complete = 'Y', qty_allocated = 0, disposition = '',
             date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = 'EREYES'
FROM oe_line l JOIN oe_hdr h ON h.order_no = l.order_no
WHERE h.projected_order = 'Y' AND l.order_no = '4216068'
  AND (l.complete <> 'Y' OR l.complete IS NULL);
PRINT 'oe_line: ' + CAST(@@ROWCOUNT AS varchar(10));

UPDATE h SET completed = 'Y', date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = 'EREYES'
FROM oe_hdr h
WHERE h.projected_order = 'Y' AND h.order_no = '4216068'
  AND (h.completed <> 'Y' OR h.completed IS NULL);
PRINT 'oe_hdr: ' + CAST(@@ROWCOUNT AS varchar(10));

UPDATE q SET complete_flag = 'Y'
FROM quote_hdr q JOIN oe_hdr h ON h.oe_hdr_uid = q.oe_hdr_uid
WHERE h.projected_order = 'Y' AND h.order_no = '4216068'
  AND (q.complete_flag <> 'Y' OR q.complete_flag IS NULL);
PRINT 'quote_hdr: ' + CAST(@@ROWCOUNT AS varchar(10));

UPDATE ql SET line_complete_flag = 'Y'
FROM quote_line ql
JOIN oe_line l ON l.oe_line_uid = ql.oe_line_uid
JOIN oe_hdr h  ON h.order_no = l.order_no
WHERE h.projected_order = 'Y' AND l.order_no = '4216068'
  AND (ql.line_complete_flag <> 'Y' OR ql.line_complete_flag IS NULL);
PRINT 'quote_line: ' + CAST(@@ROWCOUNT AS varchar(10));

-- COMMIT TRAN;
-- ROLLBACK TRAN;
*/

------------------------------------------------------------------------------------------
-- 3) Read-only: any quote (last year) with a line that has something allocated
------------------------------------------------------------------------------------------
-- Detail
SELECT h.order_no, h.order_date, h.completed,
       l.oe_line_uid, l.line_no, l.qty_ordered, l.qty_allocated, l.complete
FROM oe_hdr h
JOIN oe_line l ON l.order_no = h.order_no
WHERE h.projected_order = 'Y'
  AND h.order_date >= DATEADD(YEAR, -1, CAST(GETDATE() AS date))
  AND l.qty_allocated > 0
ORDER BY h.order_date DESC, h.order_no, l.line_no;

-- Summary
SELECT COUNT(DISTINCT h.order_no) AS quotes_with_allocation,
       COUNT(*)                   AS lines_with_allocation,
       SUM(l.qty_allocated)       AS total_qty_allocated,
       COUNT(DISTINCT CASE WHEN l.complete <> 'Y' OR l.complete IS NULL THEN h.order_no END) AS quotes_still_open
FROM oe_hdr h
JOIN oe_line l ON l.order_no = h.order_no
WHERE h.projected_order = 'Y'
  AND h.order_date >= DATEADD(YEAR, -1, CAST(GETDATE() AS date))
  AND l.qty_allocated > 0;

------------------------------------------------------------------------------------------
-- 4) Update for the 5 quotes in section 1 (4222245, 3654565, 4008353, 2699382, 3840866).
--    Same logic as section 2. Run section 1 first. Rolls back by itself if more than 5 headers
--    would change; otherwise the transaction is left OPEN - read the PRINTed counts, then
--    COMMIT TRAN; or ROLLBACK TRAN;  (commented out - uncomment deliberately)
------------------------------------------------------------------------------------------
/*
BEGIN TRAN;

DECLARE @rc int;

UPDATE l SET complete = 'Y', qty_allocated = 0, disposition = '',
             date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = 'EREYES'
FROM oe_line l JOIN oe_hdr h ON h.order_no = l.order_no
WHERE h.projected_order = 'Y'
  AND l.order_no IN ('4222245','3654565','4008353','2699382','3840866')
  AND (l.complete <> 'Y' OR l.complete IS NULL);
PRINT 'oe_line: ' + CAST(@@ROWCOUNT AS varchar(10));

UPDATE h SET completed = 'Y', date_last_modified = CURRENT_TIMESTAMP, last_maintained_by = 'EREYES'
FROM oe_hdr h
WHERE h.projected_order = 'Y'
  AND h.order_no IN ('4222245','3654565','4008353','2699382','3840866')
  AND (h.completed <> 'Y' OR h.completed IS NULL);
SET @rc = @@ROWCOUNT;
PRINT 'oe_hdr: ' + CAST(@rc AS varchar(10)) + ' (max 5)';

UPDATE q SET complete_flag = 'Y'
FROM quote_hdr q JOIN oe_hdr h ON h.oe_hdr_uid = q.oe_hdr_uid
WHERE h.projected_order = 'Y'
  AND h.order_no IN ('4222245','3654565','4008353','2699382','3840866')
  AND (q.complete_flag <> 'Y' OR q.complete_flag IS NULL);
PRINT 'quote_hdr: ' + CAST(@@ROWCOUNT AS varchar(10));

UPDATE ql SET line_complete_flag = 'Y'
FROM quote_line ql
JOIN oe_line l ON l.oe_line_uid = ql.oe_line_uid
JOIN oe_hdr h  ON h.order_no = l.order_no
WHERE h.projected_order = 'Y'
  AND l.order_no IN ('4222245','3654565','4008353','2699382','3840866')
  AND (ql.line_complete_flag <> 'Y' OR ql.line_complete_flag IS NULL);
PRINT 'quote_line: ' + CAST(@@ROWCOUNT AS varchar(10));

IF @rc > 5
BEGIN
    PRINT 'More than 5 headers changed - rolling back.';
    ROLLBACK TRAN;
END
ELSE
    PRINT 'Counts OK? Re-run section 1 inside the transaction, then COMMIT TRAN; or ROLLBACK TRAN;';
*/
