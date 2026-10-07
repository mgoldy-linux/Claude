-- =============================================================================
-- SA-56558-Item-Issues-Status.sql
-- Server: P21.allsurfaces.com / P21   (read-only; re-run after each rebuild batch)
--
-- Source list: "sa-56558 -item issues.pdf" = Inventory Card Report By Bin, loc 342,
-- bin LOST, run 10/6 07:38 (30 items). KARSCB76 was fixed 10/7 by an extended rebuild
-- (lot header 23.639999998 vs bin 23.64).
--
-- Columns (all shown to 12 decimals - the 2-decimal screens hide the problem):
--   lost_bin_qty / lost_xref_qty  quantity still sitting in LOST (inv_bin / lot_bin_xref)
--   loc_minus_bins                inv_loc.qty_on_hand - SUM(inv_bin.quantity)   (0 = consistent)
--   loc_minus_lots                inv_loc.qty_on_hand - SUM(lot.qty_on_hand)    (0 = consistent)
--   drifted_lots                  lots whose qty <> SUM(lot_bin_xref.qty_linked) (0 = consistent)
--   needs_rebuild = 'Y'           something is out of sync -> extended Rebuild Inventory
--                                 Quantities can correct it. 'N' = a real consistent
--                                 residue; a rebuild keeps it, needs a zero-out instead.
-- =============================================================================

SELECT im.item_id,
  CONVERT(varchar(30), CAST(ISNULL(ib.quantity,0) AS decimal(38,12)))   AS lost_bin_qty,
  CONVERT(varchar(30), CAST(ISNULL(xl.q,0) AS decimal(38,12)))          AS lost_xref_qty,
  CONVERT(varchar(30), CAST(il.qty_on_hand AS decimal(19,6)))           AS loc_qoh,
  CONVERT(varchar(30), CAST(il.qty_on_hand - ISNULL(sb.q,0) AS decimal(38,12))) AS loc_minus_bins,
  CONVERT(varchar(30), CAST(il.qty_on_hand - ISNULL(sl.q,0) AS decimal(38,12))) AS loc_minus_lots,
  ISNULL(dr.drift_lots,0)                                               AS drifted_lots,
  CASE WHEN il.qty_on_hand <> ISNULL(sb.q,0) OR il.qty_on_hand <> ISNULL(sl.q,0) OR ISNULL(dr.drift_lots,0) > 0
       THEN 'Y' ELSE 'N' END                                            AS needs_rebuild
FROM inv_mast im
JOIN inv_loc il ON il.inv_mast_uid = im.inv_mast_uid AND il.location_id = 342
LEFT JOIN inv_bin ib ON ib.inv_mast_uid = im.inv_mast_uid AND ib.location_id = 342 AND ib.bin = 'LOST'
OUTER APPLY (SELECT SUM(qty_linked) q FROM lot_bin_xref x
             WHERE x.inv_mast_uid = im.inv_mast_uid AND x.location_id = 342 AND x.bin_cd = 'LOST') xl
OUTER APPLY (SELECT SUM(quantity) q FROM inv_bin b
             WHERE b.inv_mast_uid = im.inv_mast_uid AND b.location_id = 342) sb
OUTER APPLY (SELECT SUM(qty_on_hand) q FROM lot l
             WHERE l.inv_mast_uid = im.inv_mast_uid AND l.location_id = 342 AND l.delete_flag <> 'Y') sl
OUTER APPLY (SELECT COUNT(*) drift_lots FROM lot l
             WHERE l.inv_mast_uid = im.inv_mast_uid AND l.location_id = 342 AND l.delete_flag <> 'Y'
               AND l.qty_on_hand <> ISNULL((SELECT SUM(x2.qty_linked) FROM lot_bin_xref x2
                                            WHERE x2.inv_mast_uid = l.inv_mast_uid
                                              AND x2.location_id = l.location_id
                                              AND x2.lot_cd = l.lot), 0)) dr
WHERE im.item_id IN (
  'CBLAP107SG','CBLCB588NC-N','CBLSN628JMP-N','CBT32NE10MO1','CBT400001582','CBT400001720',
  'CBT80NA07R','CBVCAD8920','CBVCAS3804CB','CBVCHS5481CB','CBVCHS5487CB','CBVCPR9258',
  'CBVEWH7040','CBVGEMZ704','CON58180121','CON72050121','CON88000121','CONAP950121',
  'JOHFM18205','JOHPHS17807','JOHSV22301','JOHSV22308','KARRKP8209','KARSCB76','KARSCB81',
  'KARVGW81T','LFCLOHOI900500','LFCOUBAII900110','LFCWISPII900501-15','LFVNF-LOV8517-HDC')
ORDER BY needs_rebuild DESC, im.item_id;
