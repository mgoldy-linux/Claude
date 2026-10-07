-- =============================================================================
-- SA-56558-Zero-LOST-Residue-PROD.sql
-- Server: P21.allsurfaces.com   Database: P21   (PRODUCTION)
--
-- PURPOSE
--   Clear the sub-penny leftover quantities (e.g. 0.003) in the location 342 LOST bin for
--   the items on "sa-56558 -item issues.pdf". Same logic as SA-56558-Zero-LOST-Residue-Play.sql,
--   which was dry-run and committed in Play on 10/7 (14 bin / 18 lot-bin / 18 lot / 14 loc rows).
--
-- HOW IT WORKS - removes ONLY the residue, by subtraction:
--   residue    = each LOST lot_bin_xref row with 0 < |qty_linked| < @MaxResidue (nothing allocated)
--   1. lot_bin_xref.qty_linked -> 0 for those rows
--   2. lot.qty_on_hand         -= that lot's residue   (skipped if the lot header never held it)
--   3. inv_bin LOST row        -= bin_remove (whole row if the row is < @MaxResidue, else the xref residue)
--   4. inv_loc.qty_on_hand     -= bin_remove
--   Results within 0.00001 of a 3-decimal value are snapped to it. Rows are stamped with
--   last_maintained_by = 'SA56558_zero_lost_residue'.
--   Skipped (and listed): location total not within @MaxResidue of bin total, allocation on the
--   LOST rows, bin would go negative.
--
-- PROD SAFETY
--   * @Commit = 0 (default) is a PREVIEW: no UPDATE is issued and no transaction is opened.
--     It lists every row that WOULD change. Review it, then set @Commit = 1.
--   * @Commit = 1 runs the updates in ONE transaction, checks the changed-row counts against the
--     preview, and rolls back + errors if they differ.
--   * Every change is written to dbo.asi_sa56558_lost_cleanup_log (created on the first commit)
--     so there is a permanent before/after record - no inv_tran is posted for this.
--   * KARSCB76 (fixed 10/7) and JOHFM18205 (764.80 location-vs-bin gap) are NOT in scope.
--   * Triggers fire on these tables (lot audit trail, bin stock status, ECC sync on inv_loc).
--     Run when order entry is quiet; quantities change by sub-penny amounts only.
--   * No GL posting. A later Rebuild Inventory Quantities (rebuilds from inv_tran) could bring a
--     residue back - re-run SA-56558-Item-Issues-Status.sql after any rebuild on these items.
--
-- AFTER RUNNING: re-run SA-56558-Item-Issues-Status.sql (Prod) and compare.
-- =============================================================================

USE P21;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Commit      bit           = 1;                      -- 0 = PREVIEW only, 1 = apply
DECLARE @MaxResidue  decimal(19,9) = 0.02;                   -- "sub-penny" ceiling per row
DECLARE @Location    decimal(19,0) = 342;
DECLARE @Bin         varchar(20)   = 'LOST';
DECLARE @Stamp       varchar(30)   = 'SA56558_zero_lost_residue';
DECLARE @Now         datetime      = dbo.p21_fn_GetSystemDatetime(CURRENT_TIMESTAMP, NULL, NULL);
DECLARE @Db          sysname       = DB_NAME();

IF @Db <> 'P21'
BEGIN
    RAISERROR('Safety stop: this script is Prod-only (current database is %s). Use the Play script for Play.', 16, 1, @Db);
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

-- ---- the plan: exactly what the update will do (computed without writing anything) ----
IF OBJECT_ID('tempdb..#plan') IS NOT NULL DROP TABLE #plan;
SELECT step, inv_mast_uid, row_key, before_qty, after_qty
INTO   #plan
FROM (
    SELECT 1 AS step, x.inv_mast_uid, CONVERT(varchar(120), 'lot ' + x.lot_cd + ' / bin ' + x.bin_cd) AS row_key,
           CAST(x.qty_linked AS decimal(38,12)) AS before_qty, CAST(0 AS decimal(38,12)) AS after_qty
    FROM #x1 x
    UNION ALL
    SELECT 2, l.inv_mast_uid, 'lot ' + l.lot, CAST(l.qty_on_hand AS decimal(38,12)),
           CAST(CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END AS decimal(38,12))
    FROM lot l JOIN #l1 c ON c.inv_mast_uid = l.inv_mast_uid AND c.lot = l.lot
    CROSS APPLY (SELECT q = l.qty_on_hand - c.removed) v
    WHERE l.location_id = @Location
    UNION ALL
    SELECT 3, b.inv_mast_uid, 'bin ' + b.bin, CAST(b.quantity AS decimal(38,12)),
           CAST(CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END AS decimal(38,12))
    FROM inv_bin b JOIN #b1 c ON c.inv_mast_uid = b.inv_mast_uid
    CROSS APPLY (SELECT q = b.quantity - c.bin_remove) v
    WHERE b.location_id = @Location AND b.bin = @Bin
    UNION ALL
    SELECT 4, il.inv_mast_uid, 'inv_loc ' + CONVERT(varchar(10), il.location_id), CAST(il.qty_on_hand AS decimal(38,12)),
           CAST(CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END AS decimal(38,12))
    FROM inv_loc il JOIN #b1 c ON c.inv_mast_uid = il.inv_mast_uid
    CROSS APPLY (SELECT q = il.qty_on_hand - c.bin_remove) v
    WHERE il.location_id = @Location
) p;

-- ---- review (preview or pre-apply) ----
SELECT 'SKIPPED (not changed)' AS result, item_id, reason FROM #skip ORDER BY item_id;

SELECT p.step,
       CHOOSE(p.step, 'lot_bin_xref', 'lot', 'inv_bin', 'inv_loc') AS tbl,
       im.item_id, p.row_key,
       CONVERT(varchar(40), p.before_qty) AS before_qty, CONVERT(varchar(40), p.after_qty) AS after_qty
FROM   #plan p JOIN inv_mast im ON im.inv_mast_uid = p.inv_mast_uid
ORDER BY im.item_id, p.step, p.row_key;

SELECT step, COUNT(*) AS rows_planned FROM #plan GROUP BY step ORDER BY step;

IF @Commit = 0
BEGIN
    PRINT 'PREVIEW ONLY - nothing was changed. Review the lists above, then set @Commit = 1.';
    RETURN;
END;

-- =============================================================================
-- APPLY (@Commit = 1)
-- =============================================================================
IF OBJECT_ID('dbo.asi_sa56558_lost_cleanup_log') IS NULL
    CREATE TABLE dbo.asi_sa56558_lost_cleanup_log (
        log_uid      int IDENTITY(1,1) PRIMARY KEY,
        run_at       datetime       NOT NULL,
        run_by       sysname        NOT NULL,
        location_id  decimal(19,0)  NOT NULL,
        step         tinyint        NOT NULL,
        tbl          varchar(20)    NOT NULL,
        inv_mast_uid int            NOT NULL,
        item_id      varchar(60)    NULL,
        row_key      varchar(120)   NOT NULL,
        before_qty   decimal(38,12) NULL,
        after_qty    decimal(38,12) NULL
    );

-- a new table has no grants: give it the same ones the other asi_ tables carry, plus the runner,
-- then REFUSE TO START if the runner still cannot insert (found 10/7: INSERT denied after the updates ran)
IF HAS_PERMS_BY_NAME('dbo.asi_sa56558_lost_cleanup_log', 'OBJECT', 'INSERT') = 0
BEGIN
    BEGIN TRY
        -- roles only: SQL Server will not let a login grant to itself; the runner gets access via PxxiUser
        GRANT INSERT, SELECT ON dbo.asi_sa56558_lost_cleanup_log TO p21_application_role, PxxiUser;
    END TRY
    BEGIN CATCH
        PRINT 'Could not grant on the log table: ' + ERROR_MESSAGE();
    END CATCH;
END;

IF HAS_PERMS_BY_NAME('dbo.asi_sa56558_lost_cleanup_log', 'OBJECT', 'INSERT') = 0
BEGIN
    RAISERROR('Safety stop: no INSERT permission on dbo.asi_sa56558_lost_cleanup_log - nothing was changed. Run the GRANT from an admin login (a-mgoldyn) and rerun.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#chg') IS NOT NULL DROP TABLE #chg;
CREATE TABLE #chg (
    step         tinyint,
    inv_mast_uid int,
    row_key      varchar(120),
    before_qty   decimal(38,12),
    after_qty    decimal(38,12)
);

BEGIN TRY
BEGIN TRAN;

-- 1) lot_bin_xref residue in LOST -> 0
UPDATE x
SET    x.qty_linked = 0, x.last_maintained_by = @Stamp, x.date_last_modified = @Now
OUTPUT 1, deleted.inv_mast_uid, 'lot ' + deleted.lot_cd + ' / bin ' + deleted.bin_cd, deleted.qty_linked, inserted.qty_linked
INTO   #chg (step, inv_mast_uid, row_key, before_qty, after_qty)
FROM   lot_bin_xref x
JOIN   #x1 c ON c.inv_mast_uid = x.inv_mast_uid AND c.lot_cd = x.lot_cd AND c.bin_cd = x.bin_cd
WHERE  x.location_id = @Location;

-- 2) lot header -= residue (snap noise to 3 decimals)
UPDATE l
SET    l.qty_on_hand = CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END,
       l.last_maintained_by = @Stamp, l.date_last_modified = @Now
OUTPUT 2, deleted.inv_mast_uid, 'lot ' + deleted.lot, deleted.qty_on_hand, inserted.qty_on_hand
INTO   #chg (step, inv_mast_uid, row_key, before_qty, after_qty)
FROM   lot l
JOIN   #l1 c ON c.inv_mast_uid = l.inv_mast_uid AND c.lot = l.lot
CROSS APPLY (SELECT q = l.qty_on_hand - c.removed) v
WHERE  l.location_id = @Location;

-- 3) LOST bin row -= bin_remove
UPDATE b
SET    b.quantity = CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END,
       b.last_maintained_by = @Stamp, b.date_last_modified = @Now
OUTPUT 3, deleted.inv_mast_uid, 'bin ' + deleted.bin, deleted.quantity, inserted.quantity
INTO   #chg (step, inv_mast_uid, row_key, before_qty, after_qty)
FROM   inv_bin b
JOIN   #b1 c ON c.inv_mast_uid = b.inv_mast_uid
CROSS APPLY (SELECT q = b.quantity - c.bin_remove) v
WHERE  b.location_id = @Location AND b.bin = @Bin;

-- 4) location total -= bin_remove
UPDATE il
SET    il.qty_on_hand = CASE WHEN ABS(v.q - ROUND(v.q, 3)) < 0.00001 THEN ROUND(v.q, 3) ELSE v.q END,
       il.last_maintained_by = @Stamp, il.date_last_modified = @Now
OUTPUT 4, deleted.inv_mast_uid, 'inv_loc ' + CONVERT(varchar(10), deleted.location_id), deleted.qty_on_hand, inserted.qty_on_hand
INTO   #chg (step, inv_mast_uid, row_key, before_qty, after_qty)
FROM   inv_loc il
JOIN   #b1 c ON c.inv_mast_uid = il.inv_mast_uid
CROSS APPLY (SELECT q = il.qty_on_hand - c.bin_remove) v
WHERE  il.location_id = @Location;

-- guard: what changed must equal what was previewed, row for row per step
IF EXISTS (SELECT 1 FROM (SELECT step, COUNT(*) n FROM #plan GROUP BY step) p
           FULL JOIN (SELECT step, COUNT(*) n FROM #chg GROUP BY step) c ON c.step = p.step
           WHERE ISNULL(p.n,0) <> ISNULL(c.n,0))
    RAISERROR('Changed-row counts do not match the preview - rolling back.', 16, 1);

-- permanent before/after record
INSERT INTO dbo.asi_sa56558_lost_cleanup_log (run_at, run_by, location_id, step, tbl, inv_mast_uid, item_id, row_key, before_qty, after_qty)
SELECT @Now, SUSER_SNAME(), @Location, c.step, CHOOSE(c.step, 'lot_bin_xref', 'lot', 'inv_bin', 'inv_loc'),
       c.inv_mast_uid, im.item_id, c.row_key, c.before_qty, c.after_qty
FROM   #chg c JOIN inv_mast im ON im.inv_mast_uid = c.inv_mast_uid;

COMMIT TRAN;
PRINT 'COMMITTED. Before/after rows are in dbo.asi_sa56558_lost_cleanup_log.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    PRINT 'ROLLED BACK - nothing was changed.';
    THROW;
END CATCH;

SELECT step, COUNT(*) AS rows_changed FROM #chg GROUP BY step ORDER BY step;
