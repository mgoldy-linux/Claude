-- =============================================================================
-- SA-56558-LOST-Bin-Settings-All-Locations.sql
-- Server: P21.allsurfaces.com / database P21   (read-only)
--
-- PURPOSE
--   Show every LOST-style bin at every location with the flags that make P21's
--   lot validation (d_ds_lot_bin_validation) treat its stock as "non-pickable":
--   frozen, pick-locked, consolidation, or bin type non-pickable / quarantine.
--   Stock in such a bin cannot be written off ("There is not enough quantity
--   available in lot ...") until it is moved to a pickable bin.
--
--   blocks_writeoff = 'Y' means this bin trips the non-pickable check
--   (only applies when system_setting use_advanced_bin_tracking = 'Y' AND
--   inv_loc.lot_bin_integration = 'Y' for the item).
-- =============================================================================

SELECT  b.location_id,
        l.location_name,
        b.bin_id,
        b.delete_flag,
        b.frozen_flag,
        b.pick_locked_flag,
        b.put_locked_flag,
        b.consolidation_bin_flag,
        bt.bin_type,
        bt.bin_type_desc,
        bt.pickable_flag,
        bt.quarantine_flag,
        CASE WHEN b.frozen_flag = 'Y' OR b.pick_locked_flag = 'Y' OR b.consolidation_bin_flag = 'Y'
               OR bt.pickable_flag = 'N' OR bt.quarantine_flag = 'Y'
             THEN 'Y' ELSE 'N' END                                        AS blocks_writeoff,
        ISNULL(s.bin_rows, 0)                                             AS inv_bin_rows,
        ISNULL(s.exact_zero_rows, 0)                                      AS exact_zero_rows,
        ISNULL(s.sub_penny_rows, 0)                                       AS sub_penny_rows,
        ISNULL(s.real_qty_rows, 0)                                        AS real_qty_rows,
        ISNULL(s.real_qty_total, 0)                                       AS real_qty_total
FROM    bin b
LEFT JOIN bin_type bt ON bt.bin_type_uid = b.bin_type_uid
LEFT JOIN location l  ON l.location_id   = b.location_id
OUTER APPLY (
        SELECT  COUNT(*)                                                                AS bin_rows,
                SUM(CASE WHEN ib.quantity = 0 THEN 1 ELSE 0 END)                        AS exact_zero_rows,
                SUM(CASE WHEN ib.quantity <> 0 AND ABS(ib.quantity) < 0.01 THEN 1 ELSE 0 END) AS sub_penny_rows,
                SUM(CASE WHEN ABS(ib.quantity) >= 0.01 THEN 1 ELSE 0 END)               AS real_qty_rows,
                SUM(CASE WHEN ABS(ib.quantity) >= 0.01 THEN ib.quantity ELSE 0 END)     AS real_qty_total
        FROM    inv_bin ib
        WHERE   ib.location_id = b.location_id
          AND   ib.bin         = b.bin_id) s
WHERE   b.bin_id LIKE '%LOST%'
ORDER BY b.delete_flag, b.location_id, b.bin_id;
