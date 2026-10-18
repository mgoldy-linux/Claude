-- Orders stuck at oe_hdr.completed = 'T' after a batch under AHI\vvasquez, 2026-09-30 09:34:07-09:34:43.
-- Audit trail: 574 orders flipped completed N -> T in ~36 seconds (same session also allocated stock,
-- set disposition B -> NULL on 65 orders, and changed last_rec_po / moving_average_cost on ~7 items).
-- This script resets ONLY the header flag. It does not touch oe_line, allocations or disposition.
-- Run order: 1) preview  2) backup  3) update (inside the transaction, check the count first).
USE P21;
SET NOCOUNT ON;

DECLARE @window_start datetime = '2026-09-30 09:34:00';
DECLARE @window_end   datetime = '2026-09-30 09:36:00';

-- 1) Preview: orders flipped N -> T by vvasquez in the window AND still T / still last touched by vvasquez
SELECT COUNT(*) AS still_stuck
FROM oe_hdr h
WHERE h.completed = 'T'
  AND h.delete_flag = 'N'
  AND h.last_maintained_by = 'vvasquez'
  AND h.date_last_modified >= @window_start AND h.date_last_modified < @window_end
  AND EXISTS (SELECT 1 FROM audit_trail a
              WHERE a.key1_value = CAST(h.order_no AS varchar(30))
                AND a.created_by = 'AHI\vvasquez'
                AND a.column_changed = 'completed'
                AND a.old_value = 'N' AND a.new_value = 'T'
                AND a.date_created >= @window_start AND a.date_created < @window_end);

-- 2) Backup (the record of what was changed; do not skip)
IF OBJECT_ID('zz_oe_hdr_completed_T_bkp_20261001') IS NULL
BEGIN
    SELECT h.order_no, h.completed, h.last_maintained_by, h.date_last_modified,
           GETDATE() AS backed_up_on
    INTO zz_oe_hdr_completed_T_bkp_20261001
    FROM oe_hdr h
    WHERE h.completed = 'T'
      AND h.delete_flag = 'N'
      AND h.last_maintained_by = 'vvasquez'
      AND h.date_last_modified >= @window_start AND h.date_last_modified < @window_end
      AND EXISTS (SELECT 1 FROM audit_trail a
                  WHERE a.key1_value = CAST(h.order_no AS varchar(30))
                    AND a.created_by = 'AHI\vvasquez'
                    AND a.column_changed = 'completed'
                    AND a.old_value = 'N' AND a.new_value = 'T'
                    AND a.date_created >= @window_start AND a.date_created < @window_end);
END
SELECT COUNT(*) AS rows_in_backup FROM zz_oe_hdr_completed_T_bkp_20261001;

-- 3) Update. Leave as ROLLBACK until the rows_updated count matches rows_in_backup, then change to COMMIT.
BEGIN TRAN;

UPDATE h
SET h.completed = 'N',
    h.last_maintained_by = 'mgoldyn',
    h.date_last_modified = GETDATE()
FROM oe_hdr h
JOIN zz_oe_hdr_completed_T_bkp_20261001 b ON b.order_no = h.order_no
WHERE h.completed = 'T'
  AND h.last_maintained_by = 'vvasquez'
  AND h.date_last_modified = b.date_last_modified;   -- skips any order someone has saved since the backup

SELECT @@ROWCOUNT AS rows_updated;

--ROLLBACK TRAN;   -- change to COMMIT TRAN after the count is checked
COMMIT TRAN;