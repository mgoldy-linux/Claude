-- PROD: close quote_line / quote_hdr flags that block "delete location 122 from item" (for Efrain)
-- No ticket. Item Maintenance error: "Item is on an open sales order line."
-- Cause (XE trace on Play, d_ds_oe_line_incomplete): P21 also blocks on quote_line.line_complete_flag = 'N'
-- for non-deleted oe_line rows at the location (source_loc_id OR ship_loc_id), even when the order is
-- completed. These are converted quotes (projected_order = 'N') whose quote side was never closed.
-- Efrain's earlier update filters projected_order = 'Y', so it does NOT catch them.
--
-- Lines found in PROD by the blocker check (all complete = 'Y', order completed = 'Y', loc 122):
--     AFCA020810F       order 1539868  oe_line_uid 1260361
--     AFCA020912F       order 1539868  oe_line_uid 1260359
--     CARGLACIER38ANTI  order 4228343  oe_line_uid 7606472
--     MDPCM2199HTI12    order 3361177  oe_line_uid 5490769
--     ROPC60C83P177     order 3353055  oe_line_uid 5472082
--
-- Only quote_line / quote_hdr are touched. Do NOT run the oe_line / oe_hdr updates from the original
-- script: these orders are already complete, and the oe_line update also zeroes qty_allocated and
-- clears disposition.
--
-- Transaction is left OPEN: read the PRINTed counts and the "after" result, then COMMIT TRAN; or
-- ROLLBACK TRAN;  It rolls back by itself if quote_line is not exactly 5 rows.
-- Verified in Play first? (Play fix script: Fix-Quote-Line-Flags-Loc122-Item-Delete-Play.sql)
-- Column names come from the trace and earlier scripts, not verified against the schema.

USE P21;
GO

-- 1) Before
SELECT oh.order_no, oh.completed, ol.oe_line_uid, ol.complete AS line_complete,
       ql.line_complete_flag, qh.complete_flag AS quote_hdr_complete
FROM quote_line ql
JOIN oe_line ol ON ol.oe_line_uid = ql.oe_line_uid
JOIN oe_hdr  oh ON oh.order_no    = ol.order_no
LEFT JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid
WHERE ol.oe_line_uid IN (1260361, 1260359, 7606472, 5490769, 5472082)
ORDER BY oh.order_no, ol.oe_line_uid;
GO

BEGIN TRAN;

DECLARE @rc_line int, @rc_hdr int;

UPDATE ql SET line_complete_flag = 'Y'
FROM quote_line ql
WHERE ql.oe_line_uid IN (1260361, 1260359, 7606472, 5490769, 5472082)
  AND ql.line_complete_flag = 'N';
SET @rc_line = @@ROWCOUNT;
PRINT 'quote_line: ' + CAST(@rc_line AS varchar(10)) + ' (expect 5)';

UPDATE q SET complete_flag = 'Y'
FROM quote_hdr q
JOIN oe_hdr h ON h.oe_hdr_uid = q.oe_hdr_uid
WHERE h.order_no IN ('1539868', '4228343', '3361177', '3353055')
  AND q.complete_flag = 'N'
  AND NOT EXISTS (SELECT 1
                  FROM quote_line ql2
                  JOIN oe_line ol2 ON ol2.oe_line_uid = ql2.oe_line_uid
                  WHERE ol2.order_no = h.order_no
                    AND ol2.delete_flag = 'N'
                    AND ql2.line_complete_flag = 'N');
SET @rc_hdr = @@ROWCOUNT;
PRINT 'quote_hdr: ' + CAST(@rc_hdr AS varchar(10)) + ' (expect up to 4)';

IF @rc_line <> 5
BEGIN
    PRINT 'Expected 5 quote_line rows - rolling back.';
    ROLLBACK TRAN;
END
ELSE
BEGIN
    -- 2) After (inside the transaction)
    SELECT oh.order_no, ol.oe_line_uid, ql.line_complete_flag, qh.complete_flag AS quote_hdr_complete
    FROM quote_line ql
    JOIN oe_line ol ON ol.oe_line_uid = ql.oe_line_uid
    JOIN oe_hdr  oh ON oh.order_no    = ol.order_no
    LEFT JOIN quote_hdr qh ON qh.oe_hdr_uid = oh.oe_hdr_uid
    WHERE ol.oe_line_uid IN (1260361, 1260359, 7606472, 5490769, 5472082)
    ORDER BY oh.order_no, ol.oe_line_uid;

    PRINT 'Counts OK? COMMIT TRAN;  or  ROLLBACK TRAN;';
END
GO

-- 3) After COMMIT: re-run the blocker check for the 5 items at loc 122 (expect no rows), then retry the
--    delete in Item Maintenance in Prod.
