-- =============================================================================
-- SA-56558-Zero-LOST-Residue-Play.sql
-- Server: P21Dev.allsurfaces.com   Database: P21Play   (PLAY FIRST)
--
-- PURPOSE
--   Clear the sub-penny leftover quantities (e.g. 0.003) sitting in the location 342
--   LOST bin for the items on "sa-56558 -item issues.pdf". They display as 0.00, round to
--   a zero-quantity adjustment line (which P21 drops), and Rebuild Inventory Quantities
--   keeps them because the lot / bin / location numbers already agree.
--
-- HOW IT WORKS (same technique as P21's own p21_rebuild_zero_lot_bin: a bare UPDATE stamped
-- with a recognizable last_maintained_by). It removes ONLY the residue, by subtraction:
--   residue    = each LOST lot_bin_xref row with 0 < |qty_linked| < @MaxResidue (nothing allocated)
--   1. lot_bin_xref.qty_linked -> 0 for those rows
--   2. lot.qty_on_hand         -= that lot's residue   (skipped if the lot header never held it)
--   3. inv_bin LOST row        -= bin_remove, where bin_remove = the whole row if the row itself
--                                 is < @MaxResidue, otherwise the sum of its xref residue
--                                 (a bin that also holds real stock keeps the real stock)
--   4. inv_loc.qty_on_hand     -= bin_remove
--   Results within 0.00001 of a 3-decimal value are snapped to it (e.g. 0.000999994 -> 0,
--   195.859999161 -> 195.86) so the cleanup does not leave new noise behind.
--   Safety: an item is SKIPPED (and listed) if its location total is not within @MaxResidue of
--   its bin total, if the LOST rows have any allocation, or if the bin would go negative.
--
-- WHAT IT DOES NOT DO
--   * No inv_tran / GL posting (sub-penny value, well under $0.01 per item). Because no
--     transaction is posted, a later Rebuild Inventory Quantities (which rebuilds from
--     inv_tran) could bring a residue back -> after the Play commit, run the rebuild on
--     ONE cleaned item and re-run the check to see.
--   * Real stock is never touched.
--   * KARSCB76 (already fixed) and JOHFM18205 (764.80 location-vs-bin gap) are not in scope.
--
-- TRIGGERS: inv_loc / lot / lot_bin_xref / inv_bin have triggers (lot audit trail, bin stock
-- status, ECC sync on inv_loc). Play only for now; expect audit_trail rows from the lot update.
--
-- USAGE
--   1. Run as is: @Commit = 0 is a DRY RUN - it applies the updates, shows every change and
--      the after-state, then ROLLS BACK.
--   2. Review the result sets. If good, set @Commit = 1 and run again.
--   3. Re-run SA-56558-Item-Issues-Status.sql (against P21Play) to confirm.
--   Do NOT point this at Prod until the Play commit + rebuild test is proven. NOTE: Play is an
--   older copy than Prod, so its residues differ from the PDF - judge the logic, not the item list.
-- =============================================================================

USE P21Play;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Commit      bit           = 1  ;                      -- 0 = dry run (rollback), 1 = commit
DECLARE @MaxResidue  decimal(19,9) = 0.02;                   -- "sub-penny" ceiling per row
DECLARE @Location    decimal(19,0) = 342;
DECLARE @Bin         varchar(20)   = 'LOST';
DECLARE @Stamp       varchar(30)   = 'SA56558_zero_lost_residue';
DECLARE @Now         datetime      = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP, NULL, NULL);
DECLARE @Db          sysname       = DB_NAME();

IF @Db <> 'P21Play'
BEGIN
    RAISERROR('Safety stop: this script is Play-only (current database is %s).', 16, 1, @Db);
    RETURN;
END;

-- ---- scope: the PDF items minus KARSCB76 (fixed) and JOHFM18205 (needs its own look) ----
IF OBJECT_ID('tempdb..#items') IS NOT NULL DROP TABLE #items;
SELECT im.inv_mast_uid, im.item_id
INTO   #items
FROM   inv_mast im
WHERE  im.item_id IN (
  'CBLAP107SG','CBLCB588NC-N','CBLSN628JMP-N','CBT32NE10MO1','CBT400001582','CBT400001720',
  'CBT80NA07R','CBVCAD8920','CBVCAS3804CB','CBVCHS5481CB','CBVCHS5487CB','CBVCPR9258',
  'CBVEWH7040','CBVGEMZ704','CON58180121','CON72050121','CON88000121','CONAP950121',
  'JOHPHS17807','JOHSV22301','JOHSV22308','KARRKP8209','KARSCB81',
  'KARVGW81T','LFCLOHOI900500','LFCOUBAII900110','LFCWISPII900501-15','LFVNF-LOV8517-HDC');

-- ---- residue rows in LOST (xref level) ----
IF OBJECT_ID('tempdb..#x1') IS NOT NULL DROP TABLE #x1;
SELECT x.inv_mast_uid, x.lot_cd, x.bin_cd, x.qty_linked
INTO   #x1
FROM   lot_bin_xref x
JOIN   #items i ON i.inv_mast_uid = x.inv_mast_uid
WHERE  x.location_id = @Location AND x.bin_cd = @Bin
  AND  x.qty_linked <> 0 AND ABS(x.qty_linked) < @MaxResidue AND x.qty_allocated = 0;

-- ---- per item: how much to take out of the LOST bin row and the location total ----
IF OBJECT_ID('tempdb..#b1') IS NOT NULL DROP TABLE #b1;
SELECT i.inv_mast_uid, i.item_id, b.quantity AS bin_qty, il.qty_on_hand AS loc_qty,
       CASE WHEN ABS(b.quantity) < @MaxResidue THEN b.quantity ELSE ISNULL(xs.q, 0) END AS bin_remove
INTO   #b1
FROM   #items i
JOIN   inv_loc il ON il.inv_mast_uid = i.inv_mast_uid AND il.location_id = @Location
JOIN   inv_bin b  ON b.inv_mast_uid  = i.inv_mast_uid AND b.location_id  = @Location AND b.bin = @Bin
OUTER APPLY (SELECT SUM(qty_linked) q FROM #x1 x WHERE x.inv_mast_uid = i.inv_mast_uid) xs
WHERE  b.qty_allocated = 0
  AND  (ABS(b.quantity) < @MaxResidue OR xs.q IS NOT NULL);

-- ---- items we refuse to touch ----
IF OBJECT_ID('tempdb..#skip') IS NOT NULL DROP TABLE #skip;
SELECT i.inv_mast_uid, i.item_id,
       CASE WHEN il.inv_mast_uid IS NULL                                              THEN 'not stocked at this location'
            WHEN ABS(il.qty_on_hand - ISNULL(sb.q,0)) >= @MaxResidue                  THEN 'location total vs bin total gap >= ceiling'
            WHEN ISNULL(al.q,0) <> 0                                                  THEN 'allocation on LOST rows'
            WHEN b1.inv_mast_uid IS NOT NULL AND b1.bin_qty - b1.bin_remove < -0.00001 THEN 'bin would go negative'
            END AS reason
INTO   #skip
FROM   #items i
LEFT JOIN inv_loc il ON il.inv_mast_uid = i.inv_mast_uid AND il.location_id = @Location
LEFT JOIN #b1 b1     ON b1.inv_mast_uid = i.inv_mast_uid
OUTER APPLY (SELECT SUM(quantity) q FROM inv_bin b
             WHERE b.inv_mast_uid = i.inv_mast_uid AND b.location_id = @Location) sb
OUTER APPLY (SELECT SUM(ABS(qty_allocated)) q FROM
               (SELECT qty_allocated FROM inv_bin      WHERE inv_mast_uid = i.inv_mast_uid AND location_id = @Location AND bin    = @Bin
                UNION ALL
                SELECT qty_allocated FROM lot_bin_xref WHERE inv_mast_uid = i.inv_mast_uid AND location_id = @Location AND bin_cd = @Bin) a) al
WHERE  il.inv_mast_uid IS NULL
   OR  ABS(il.qty_on_hand - ISNULL(sb.q,0)) >= @MaxResidue
   OR  ISNULL(al.q,0) <> 0
   OR  (b1.inv_mast_uid IS NOT NULL AND b1.bin_qty - b1.bin_remove < -0.00001);

DELETE FROM #x1 WHERE inv_mast_uid IN (SELECT inv_mast_uid FROM #skip);
DELETE FROM #b1 WHERE inv_mast_uid IN (SELECT inv_mast_uid FROM #skip) OR bin_remove = 0;

-- ---- lots whose header actually included the residue ----
IF OBJECT_ID('tempdb..#l1') IS NOT NULL DROP TABLE #l1;
SELECT l.inv_mast_uid, l.lot, r.removed
INTO   #l1
FROM   lot l
JOIN   (SELECT inv_mast_uid, lot_cd, SUM(qty_linked) AS removed FROM #x1 GROUP BY inv_mast_uid, lot_cd) r
         ON r.inv_mast_uid = l.inv_mast_uid AND r.lot_cd = l.lot
WHERE  l.location_id = @Location AND l.delete_flag <> 'Y'
  AND  l.qty_on_hand - r.removed >= -0.00001;

-- ---- change log (filled by OUTPUT ... INTO so it works with the table triggers) ----
IF OBJECT_ID('tempdb..#chg') IS NOT NULL DROP TABLE #chg;
CREATE TABLE #chg (
    step         tinyint,
    inv_mast_uid int,
    item_id      varchar(60) NULL,
    row_key      varchar(120),
    before_qty   decimal(38,12),
    after_qty    decimal(38,12)
);

BEGIN TRAN;

-- 1) lot_bin_xref residue in LOST -> 0
UPDATE x
SET    x.qty_linked = 0, x.last_maintained_by = @Stamp, x.date_last_modified = @Now
OUTPUT 1, deleted.inv_mast_uid, NULL, 'lot ' + deleted.lot_cd + ' / bin ' + deleted.bin_cd, deleted.qty_linked, inserted.qty_linked
INTO   #chg (step, inv_mast_uid, item_id, row_key, before_qty, after_qty)
FROM   lot_bin_xref x
JOIN   #x1 c ON c.inv_mast_uid = x.inv_mast_uid AND c.lot_cd = x.lot_cd AND c.bin_cd = x.bin_cd
WHERE  x.location_id = @Location;

-- 2) lot header -= residue (snap noise to 3 decimals)
UPDATE l
SET    l.qty_on_hand = CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END,
       l.last_maintained_by = @Stamp, l.date_last_modified = @Now
OUTPUT 2, deleted.inv_mast_uid, NULL, 'lot ' + deleted.lot, deleted.qty_on_hand, inserted.qty_on_hand
INTO   #chg (step, inv_mast_uid, item_id, row_key, before_qty, after_qty)
FROM   lot l
JOIN   #l1 c ON c.inv_mast_uid = l.inv_mast_uid AND c.lot = l.lot
CROSS APPLY (SELECT q = l.qty_on_hand - c.removed) v
WHERE  l.location_id = @Location;

-- 3) LOST bin row -= bin_remove
UPDATE b
SET    b.quantity = CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END,
       b.last_maintained_by = @Stamp, b.date_last_modified = @Now
OUTPUT 3, deleted.inv_mast_uid, NULL, 'bin ' + deleted.bin, deleted.quantity, inserted.quantity
INTO   #chg (step, inv_mast_uid, item_id, row_key, before_qty, after_qty)
FROM   inv_bin b
JOIN   #b1 c ON c.inv_mast_uid = b.inv_mast_uid
CROSS APPLY (SELECT q = b.quantity - c.bin_remove) v
WHERE  b.location_id = @Location AND b.bin = @Bin;

-- 4) location total -= bin_remove
UPDATE il
SET    il.qty_on_hand = CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END,
       il.last_maintained_by = @Stamp, il.date_last_modified = @Now
OUTPUT 4, deleted.inv_mast_uid, NULL, 'inv_loc ' + CONVERT(varchar(10), deleted.location_id), deleted.qty_on_hand, inserted.qty_on_hand
INTO   #chg (step, inv_mast_uid, item_id, row_key, before_qty, after_qty)
FROM   inv_loc il
JOIN   #b1 c ON c.inv_mast_uid = il.inv_mast_uid
CROSS APPLY (SELECT q = il.qty_on_hand - c.bin_remove) v
WHERE  il.location_id = @Location;

UPDATE c SET c.item_id = im.item_id FROM #chg c JOIN inv_mast im ON im.inv_mast_uid = c.inv_mast_uid;

-- ---- review ----
SELECT 'SKIPPED (not changed)' AS result, item_id, reason FROM #skip ORDER BY item_id;

SELECT step,
       CHOOSE(step, 'lot_bin_xref', 'lot', 'inv_bin', 'inv_loc') AS tbl,
       item_id, row_key,
       CONVERT(varchar(40), before_qty) AS before_qty, CONVERT(varchar(40), after_qty) AS after_qty
FROM   #chg ORDER BY item_id, step, row_key;

SELECT i.item_id,
       CONVERT(varchar(30), CAST(ISNULL(ib.quantity,0) AS decimal(38,12)))                          AS lost_bin_qty_after,
       CONVERT(varchar(30), CAST(il.qty_on_hand AS decimal(19,6)))                                  AS loc_qoh_after,
       CONVERT(varchar(30), CAST(il.qty_on_hand - ISNULL(sb.q,0) AS decimal(38,12)))               AS loc_minus_bins_after
FROM   #items i
JOIN   inv_loc il ON il.inv_mast_uid = i.inv_mast_uid AND il.location_id = @Location
LEFT JOIN inv_bin ib ON ib.inv_mast_uid = i.inv_mast_uid AND ib.location_id = @Location AND ib.bin = @Bin
OUTER APPLY (SELECT SUM(quantity) q FROM inv_bin b WHERE b.inv_mast_uid = i.inv_mast_uid AND b.location_id = @Location) sb
ORDER BY i.item_id;

SELECT step, COUNT(*) AS rows_changed FROM #chg GROUP BY step ORDER BY step;

IF @Commit = 1
BEGIN
    COMMIT TRAN;
    PRINT 'COMMITTED.';
END
ELSE
BEGIN
    ROLLBACK TRAN;
    PRINT 'DRY RUN - rolled back. Set @Commit = 1 to keep the changes.';
END;
