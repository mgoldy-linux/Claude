/* ============================================================================
   Batched UPDATE: inv_loc.replenishment_method / inv_min / safety_stock_type
   ----------------------------------------------------------------------------
   Approved: 10,000 rows/batch, single combined pass (~391 batches on P21Dev's
   counts as of 2026-09-10; P21Training's actual count may differ slightly).

   Run in: P21Training first. Do NOT run against Prod from this file.

   Sequence:
     STEP 0  rollback image (before)
     STEP 1  batched update loop, with progress logging
     STEP 2  verify: should return 0 rows left to change
   ============================================================================ */
USE P21Training;
GO

/* ==== STEP 0 : rollback image before touching anything =================== */
IF OBJECT_ID('dbo.zz_inv_loc_bkp_20260911') IS NOT NULL DROP TABLE dbo.zz_inv_loc_bkp_20260911;
SELECT inv_mast_uid, location_id,
       replenishment_method, inv_min, safety_stock_type,
       date_last_modified, last_maintained_by
INTO   dbo.zz_inv_loc_bkp_20260911
FROM   dbo.inv_loc
WHERE  delete_flag = 'N';

SELECT COUNT(*) AS rows_backed_up FROM dbo.zz_inv_loc_bkp_20260911;
GO

/* ==== STEP 1 : batched update ============================================ */
IF OBJECT_ID('dbo.zz_inv_loc_batch_log') IS NULL
CREATE TABLE dbo.zz_inv_loc_batch_log (
    batch_num    INT,
    rows_updated INT,
    run_time     DATETIME2 DEFAULT SYSDATETIME()
);
GO

DECLARE @BatchSize     INT = 10000;
DECLARE @RowsAffected  INT = 1;
DECLARE @TotalRows     BIGINT = 0;
DECLARE @BatchNum      INT = 0;

WHILE @RowsAffected > 0
BEGIN
    SET @BatchNum += 1;

    UPDATE TOP (@BatchSize) dbo.inv_loc
    SET    replenishment_method = 'Up To',
           inv_min              = 0,
           safety_stock_type    = 0
    WHERE  delete_flag = 'N'
      AND  (
             (replenishment_method <> 'Up To' OR replenishment_method IS NULL)
          OR (inv_min <> 0 OR inv_min IS NULL)
          OR (safety_stock_type <> 0 OR safety_stock_type IS NULL)
           );

    SET @RowsAffected = @@ROWCOUNT;
    SET @TotalRows += @RowsAffected;

    INSERT INTO dbo.zz_inv_loc_batch_log (batch_num, rows_updated)
    VALUES (@BatchNum, @RowsAffected);

    RAISERROR('Batch %d: %d rows updated. Running total: %d', 0, 1, @BatchNum, @RowsAffected, @TotalRows) WITH NOWAIT;

    IF @RowsAffected > 0
        WAITFOR DELAY '00:00:00.250';   -- brief pause between batches
END

RAISERROR('DONE. Total batches: %d   Total rows updated: %d', 0, 1, @BatchNum, @TotalRows) WITH NOWAIT;
GO

/* ==== STEP 2 : verify nothing left to change ============================= */
SELECT COUNT(*) AS rows_still_needing_change
FROM   dbo.inv_loc
WHERE  delete_flag = 'N'
  AND  (
         (replenishment_method <> 'Up To' OR replenishment_method IS NULL)
      OR (inv_min <> 0 OR inv_min IS NULL)
      OR (safety_stock_type <> 0 OR safety_stock_type IS NULL)
       );
-- should be 0

SELECT MIN(run_time) AS started, MAX(run_time) AS finished, COUNT(*) AS batches, SUM(rows_updated) AS total_rows
FROM   dbo.zz_inv_loc_batch_log;
GO
