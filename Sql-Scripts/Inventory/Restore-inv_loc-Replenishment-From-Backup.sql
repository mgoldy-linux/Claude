/* ============================================================================
   Restore inv_loc.replenishment_method / inv_min / safety_stock_type from the
   zz_inv_loc_bkp_20260913 rollback image taken by
   Batch-Update-inv_loc-Replenishment.sql's STEP 0, before that script's
   batch update ran.

   IMPORTANT -- read before running:
     - This restores ALL THREE columns to whatever they were at backup time,
       for every row that still exists in the backup AND in inv_loc today.
       It does NOT distinguish "the bulk update's change" from any OTHER edit
       made to these same columns since then (e.g. by Purchasing during
       testing) -- a restore reverts BOTH indiscriminately. If Purchasing has
       made intentional changes to these fields since the bulk update ran,
       confirm with them before restoring, or this will undo their work too.
     - Only rows with delete_flag = 'N' in BOTH the backup and the live table
       are touched -- a row deleted since backup is left alone.
     - Rows added to inv_loc since the backup was taken are NOT in the backup
       and are therefore NOT touched (no data to restore them to).
     - If zz_inv_loc_bkp_20260913 doesn't exist, this table's most likely
       cause is a refresh-from-Prod on this environment since the backup was
       taken (refreshes wipe non-Prod artifacts) -- check the environment's
       last-refresh date before assuming something else went wrong.

   Run in: P21Training (or wherever Batch-Update-inv_loc-Replenishment.sql
   was actually run -- confirm the USE below matches).

   Sequence:
     STEP 0  pre-restore sanity check -- how many rows would actually change
     STEP 1  batched restore loop, with progress logging
     STEP 2  verify: should return 0 rows left to restore
   ============================================================================ */
USE P21Training;
GO

/* ==== STEP 0 : sanity check before restoring ============================= */
IF OBJECT_ID('dbo.zz_inv_loc_bkp_20260913') IS NULL
BEGIN
    RAISERROR('zz_inv_loc_bkp_20260913 not found -- nothing to restore from. Check whether this environment was refreshed from Prod since the backup was taken.', 16, 1);
    RETURN;
END

SELECT COUNT(*) AS rows_that_would_be_restored
FROM   dbo.inv_loc il
JOIN   dbo.zz_inv_loc_bkp_20260913 b
       ON b.inv_mast_uid = il.inv_mast_uid AND b.location_id = il.location_id
WHERE  il.delete_flag = 'N'
  AND  (
         ISNULL(il.replenishment_method,'') <> ISNULL(b.replenishment_method,'')
      OR ISNULL(il.inv_min,-999999)          <> ISNULL(b.inv_min,-999999)
      OR ISNULL(il.safety_stock_type,-999999) <> ISNULL(b.safety_stock_type,-999999)
       );
GO

/* ==== STEP 1 : batched restore ============================================ *
   >>> Confirm the STEP 0 count above is what you expect BEFORE running this. <<<
 * --------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.zz_inv_loc_restore_log') IS NULL
CREATE TABLE dbo.zz_inv_loc_restore_log (
    batch_num    INT,
    rows_restored INT,
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

    UPDATE TOP (@BatchSize) il
    SET    il.replenishment_method = b.replenishment_method,
           il.inv_min              = b.inv_min,
           il.safety_stock_type    = b.safety_stock_type
    FROM   dbo.inv_loc il
    JOIN   dbo.zz_inv_loc_bkp_20260913 b
           ON b.inv_mast_uid = il.inv_mast_uid AND b.location_id = il.location_id
    WHERE  il.delete_flag = 'N'
      AND  (
             ISNULL(il.replenishment_method,'') <> ISNULL(b.replenishment_method,'')
          OR ISNULL(il.inv_min,-999999)          <> ISNULL(b.inv_min,-999999)
          OR ISNULL(il.safety_stock_type,-999999) <> ISNULL(b.safety_stock_type,-999999)
           );

    SET @RowsAffected = @@ROWCOUNT;
    SET @TotalRows += @RowsAffected;

    INSERT INTO dbo.zz_inv_loc_restore_log (batch_num, rows_restored)
    VALUES (@BatchNum, @RowsAffected);

    RAISERROR('Batch %d: %d rows restored. Running total: %d', 0, 1, @BatchNum, @RowsAffected, CAST(@TotalRows AS INT)) WITH NOWAIT;

    IF @RowsAffected > 0
        WAITFOR DELAY '00:00:00.250';
END

RAISERROR('DONE. Total batches: %d   Total rows restored: %d', 0, 1, @BatchNum, @TotalRows) WITH NOWAIT;
GO

/* ==== STEP 2 : verify nothing left to restore ============================= */
SELECT COUNT(*) AS rows_still_differing_from_backup
FROM   dbo.inv_loc il
JOIN   dbo.zz_inv_loc_bkp_20260913 b
       ON b.inv_mast_uid = il.inv_mast_uid AND b.location_id = il.location_id
WHERE  il.delete_flag = 'N'
  AND  (
         ISNULL(il.replenishment_method,'') <> ISNULL(b.replenishment_method,'')
      OR ISNULL(il.inv_min,-999999)          <> ISNULL(b.inv_min,-999999)
      OR ISNULL(il.safety_stock_type,-999999) <> ISNULL(b.safety_stock_type,-999999)
       );
-- should be 0
GO
