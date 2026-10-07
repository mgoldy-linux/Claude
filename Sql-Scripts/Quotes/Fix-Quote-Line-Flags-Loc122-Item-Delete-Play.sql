-- Fix quote_line / quote_hdr flags that block "delete location 122 from item" (Play)
-- No ticket. Item Maintenance error: "Item is on an open sales order line."
-- Cause (from XE trace, d_ds_oe_line_incomplete): P21 also checks quote_line.line_complete_flag = 'N'
-- on non-deleted oe_line rows at the location (source_loc_id OR ship_loc_id), even when the order
-- the quote became is completed. These are converted quotes (projected_order = 'N') whose quote
-- side was never closed.
--
-- ROPC60C83P177 / order 3353055 (oe_line_uid 5472082) was fixed first and cleared the error.
-- This script fixes the 4 remaining lines found by the check query:
--     AFCA020810F       order 1539868  oe_line_uid 1260361
--     AFCA020912F       order 1539868  oe_line_uid 1260359
--     CARGLACIER38ANTI  order 4228343  oe_line_uid 7606472
--     MDPCM2199HTI12    order 3361177  oe_line_uid 5490769
--
-- Run in P21Play ONLY. Scoped to those 4 oe_line_uids. Rolls back unless exactly 4 quote_line rows
-- change. quote_hdr.complete_flag is set only when the quote has no other open quote line.
-- Column names are from the trace / earlier scripts, not verified against the schema.

USE P21Play;
GO

-- 1) Before
SELECT oh.order_no, oh.completed, ol.oe_line_uid, ol.complete AS line_complete,
       ql.line_complete_flag, qh.complete_flag AS quote_hdr_complete
FROM quote_line ql
JOIN oe_line ol ON ol.oe_line_uid = ql.oe_line_uid
JOIN oe_hdr  oh ON oh.order_no    = ol.order_no
LEFT JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid
WHERE ol.oe_line_uid IN (1260361, 1260359, 7606472, 5490769)
ORDER BY oh.order_no, ol.oe_line_uid;
GO

BEGIN TRAN;

DECLARE @rc_line int, @rc_hdr int;

UPDATE ql SET line_complete_flag = 'Y'
FROM quote_line ql
WHERE ql.oe_line_uid IN (1260361, 1260359, 7606472, 5490769)
  AND ql.line_complete_flag = 'N';
SET @rc_line = @@ROWCOUNT;
PRINT 'quote_line: ' + CAST(@rc_line AS varchar(10)) + ' (expect 4)';

UPDATE q SET complete_flag = 'Y'
FROM quote_hdr q
JOIN oe_hdr h ON h.oe_hdr_uid = q.oe_hdr_uid
WHERE h.order_no IN ('1539868', '4228343', '3361177')
  AND q.complete_flag = 'N'
  AND NOT EXISTS (SELECT 1
                  FROM quote_line ql2
                  JOIN oe_line ol2 ON ol2.oe_line_uid = ql2.oe_line_uid
                  WHERE ol2.order_no = h.order_no
                    AND ol2.delete_flag = 'N'
                    AND ql2.line_complete_flag = 'N');
SET @rc_hdr = @@ROWCOUNT;
PRINT 'quote_hdr: ' + CAST(@rc_hdr AS varchar(10)) + ' (expect up to 3)';

IF @rc_line <> 4
BEGIN
    PRINT 'Expected 4 quote_line rows - rolling back.';
    ROLLBACK TRAN;
END
ELSE
BEGIN
    -- 2) After (inside the transaction, before commit)
    SELECT oh.order_no, ol.oe_line_uid, ql.line_complete_flag, qh.complete_flag AS quote_hdr_complete
    FROM quote_line ql
    JOIN oe_line ol ON ol.oe_line_uid = ql.oe_line_uid
    JOIN oe_hdr  oh ON oh.order_no    = ol.order_no
    LEFT JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid
    WHERE ol.oe_line_uid IN (1260361, 1260359, 7606472, 5490769)
    ORDER BY oh.order_no, ol.oe_line_uid;

    COMMIT TRAN;
    PRINT 'Committed.';
END
GO

-- 3) Re-run the blocker check for the 5 items at location 122: it should now return no rows.
--    Then retry the delete in Item Maintenance (Play).
