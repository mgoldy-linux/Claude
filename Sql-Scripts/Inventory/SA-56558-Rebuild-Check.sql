-- =============================================================================
-- SA-56558-Rebuild-Check.sql
-- Server: P21.allsurfaces.com / P21   (read-only)
--
-- PURPOSE
--   After running Rebuild Inventory Quantities on some of the 30 "item issues" items
--   (loc 342, LOST bin), show which items the rebuild actually touched and whether the
--   LOST leftover cleared. Set @since to the start of your rebuild session.
--
--   touched_by_rebuild = 'Y' : an inv_bin / lot / lot_bin_xref row for the item at 342
--                              was modified since @since by a p21_rebuild_* proc or by you.
--   lost_bin_qty / lost_xref_qty : quantity still in LOST (0 = cleared).
--   still_out_of_sync = 'Y' : location total, bin total, lot total or a lot's bin total
--                              still disagree (same test as SA-56558-Item-Issues-Status.sql).
--   Quantities are shown to 12 decimals on purpose.
-- =============================================================================

DECLARE @since datetime = '2026-10-07 12:30';   -- adjust: when you started rebuilding (server local time)

SELECT im.item_id,
  CONVERT(varchar(30), CAST(ISNULL(ib.quantity,0) AS decimal(38,12)))      AS lost_bin_qty,
  CONVERT(varchar(30), CAST(ISNULL(xl.q,0) AS decimal(38,12)))             AS lost_xref_qty,
  CONVERT(varchar(30), CAST(il.qty_on_hand AS decimal(19,6)))              AS loc_qoh,
  CONVERT(varchar(30), CAST(il.qty_on_hand - ISNULL(sb.q,0) AS decimal(38,12))) AS loc_minus_bins,
  CONVERT(varchar(30), CAST(il.qty_on_hand - ISNULL(sl.q,0) AS decimal(38,12))) AS loc_minus_lots,
  ISNULL(dr.drift_lots,0)                                                  AS drifted_lots,
  CASE WHEN il.qty_on_hand <> ISNULL(sb.q,0) OR il.qty_on_hand <> ISNULL(sl.q,0) OR ISNULL(dr.drift_lots,0) > 0
       THEN 'Y' ELSE 'N' END                                               AS still_out_of_sync,
  CASE WHEN t.touches > 0 THEN 'Y' ELSE 'N' END                            AS touched_by_rebuild,
  t.last_touch,
  t.last_by
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
OUTER APPLY (
    SELECT COUNT(*) AS touches,
           MAX(u.dt) AS last_touch,
           MAX(CASE WHEN u.rn = 1 THEN u.who END) AS last_by
    FROM (SELECT date_last_modified dt, last_maintained_by who,
                 ROW_NUMBER() OVER (ORDER BY date_last_modified DESC) rn
          FROM (SELECT date_last_modified, last_maintained_by FROM inv_bin
                 WHERE inv_mast_uid = im.inv_mast_uid AND location_id = 342
                UNION ALL
                SELECT date_last_modified, last_maintained_by FROM lot
                 WHERE inv_mast_uid = im.inv_mast_uid AND location_id = 342
                UNION ALL
                SELECT date_last_modified, last_maintained_by FROM lot_bin_xref
                 WHERE inv_mast_uid = im.inv_mast_uid AND location_id = 342) a
          WHERE date_last_modified >= @since) u
) t
WHERE im.item_id IN (
  'CBLAP107SG','CBLCB588NC-N','CBLSN628JMP-N','CBT32NE10MO1','CBT400001582','CBT400001720',
  'CBT80NA07R','CBVCAD8920','CBVCAS3804CB','CBVCHS5481CB','CBVCHS5487CB','CBVCPR9258',
  'CBVEWH7040','CBVGEMZ704','CON58180121','CON72050121','CON88000121','CONAP950121',
  'JOHFM18205','JOHPHS17807','JOHSV22301','JOHSV22308','KARRKP8209','KARSCB76','KARSCB81',
  'KARVGW81T','LFCLOHOI900500','LFCOUBAII900110','LFCWISPII900501-15','LFVNF-LOV8517-HDC')
ORDER BY CASE WHEN t.touches > 0 THEN 0 ELSE 1 END, im.item_id;
