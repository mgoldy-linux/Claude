-- =============================================================================
-- SA-56558-Lots-In-LOST-Bins-Play.sql
-- Server: P21Dev.allsurfaces.com   Database: P21Play   (read-only)
--
-- PURPOSE
--   Find lots that currently have quantity in a LOST-style bin, at ANY location,
--   to pick a CONTROL lot for the SA 56558 write-off test. The failing lot is
--   KARSCB76 / V025G31 @ loc 342 (all 23.64 in LOST, nothing in any other bin).
--
--   lot_shape:
--     'ALL IN LOST'      same shape as the failing lot (lot qty entirely in non-pickable bins)
--     'PART IN LOST'     lot also has quantity in a pickable bin -> control candidate
--   NOTE: lot_shape uses exact equality, so a lot whose header is off by a hair (the real
--   SA 56558 cause: lot 23.639999998 vs bin 23.64) is labeled 'PART IN LOST' even though
--   lot_qty_outside_this_bin displays 0.00. Cast to decimal(38,12) to see it.
--   Compare how Inventory Adjustments (decrease from the LOST bin) behaves for each shape.
--   Prefer candidates with lot_bin_integration = 'Y' (the check only applies then).
-- =============================================================================

SELECT  x.location_id,
        im.item_id,
        x.lot_cd                                              AS lot,
        x.bin_cd                                              AS lost_bin,
        x.qty_linked                                          AS qty_in_lost,
        l.qty_on_hand                                         AS lot_qty_on_hand,
        l.qty_allocated                                       AS lot_qty_allocated,
        l.qty_on_hand - x.qty_linked                          AS lot_qty_outside_this_bin,
        CASE WHEN l.qty_on_hand = x.qty_linked THEN 'ALL IN LOST' ELSE 'PART IN LOST' END AS lot_shape,
        il.lot_bin_integration,
        il.track_bins,
        b.pick_locked_flag,
        bt.pickable_flag,
        bt.quarantine_flag,
        (SELECT COUNT(DISTINCT x2.bin_cd)
           FROM lot_bin_xref x2
          WHERE x2.inv_mast_uid = x.inv_mast_uid AND x2.location_id = x.location_id
            AND x2.lot_cd = x.lot_cd AND x2.qty_linked <> 0) AS bins_holding_lot
FROM    lot_bin_xref x
JOIN    inv_mast im   ON im.inv_mast_uid = x.inv_mast_uid
JOIN    lot l         ON l.inv_mast_uid = x.inv_mast_uid AND l.location_id = x.location_id AND l.lot = x.lot_cd
JOIN    inv_loc il    ON il.inv_mast_uid = x.inv_mast_uid AND il.location_id = x.location_id
JOIN    bin b         ON b.company_id = x.company_id AND b.location_id = x.location_id AND b.bin_id = x.bin_cd
LEFT JOIN bin_type bt ON bt.bin_type_uid = b.bin_type_uid
WHERE   x.bin_cd LIKE '%LOST%'
  AND   b.delete_flag = 'N'
  AND   l.delete_flag <> 'Y'
  AND   x.qty_linked >= 0.01
ORDER BY lot_shape, il.lot_bin_integration DESC, x.location_id, im.item_id, x.lot_cd;
