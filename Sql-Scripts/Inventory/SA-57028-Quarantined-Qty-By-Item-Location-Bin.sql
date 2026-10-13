-- SA 57028: items with qty_quarantined > 0, and the bin(s) the stock sits in.
-- inv_loc_stock_status is item+location only (no bin); bin comes from inv_bin (non-lot)
-- and lot_bin_xref (lot-tracked), joined to bin -> bin_type where quarantine_flag = 'Y'.
-- Run on DW (asdwdb01.ahi.local / P21): current through last night's restore.
;WITH bin_qty AS (
    SELECT b.inv_mast_uid, b.location_id, b.bin AS bin_id, b.quantity AS qty
    FROM   dbo.inv_bin b
    WHERE  b.quantity <> 0
    UNION ALL
    SELECT x.inv_mast_uid, x.location_id, x.bin_cd, x.qty_linked
    FROM   dbo.lot_bin_xref x
    WHERE  x.qty_linked <> 0
)
SELECT m.item_id,
       s.location_id,
       q.bin_id,
       bt.bin_type,
       bt.quarantine_flag,
       SUM(q.qty)           AS qty_in_bin,
       s.qty_quarantined    AS qty_quarantined_item_loc
FROM   dbo.inv_loc_stock_status s
       JOIN dbo.inv_mast m          ON m.inv_mast_uid = s.inv_mast_uid
       LEFT JOIN bin_qty q          ON q.inv_mast_uid = s.inv_mast_uid
                                   AND q.location_id  = s.location_id
       LEFT JOIN dbo.bin bn         ON bn.location_id = q.location_id
                                   AND bn.bin_id      = q.bin_id
       LEFT JOIN dbo.bin_type bt    ON bt.bin_type_uid = bn.bin_type_uid
WHERE  s.qty_quarantined > 0
GROUP  BY m.item_id, s.location_id, q.bin_id, bt.bin_type, bt.quarantine_flag, s.qty_quarantined
ORDER  BY s.location_id, m.item_id, q.bin_id;
