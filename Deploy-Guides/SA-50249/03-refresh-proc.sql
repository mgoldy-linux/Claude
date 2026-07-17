/* ============================================================================
   SA-50249  Step 03 — nightly refresh proc (lives in ASI_ReportCache, persistent)
   Runs post-restore. Rebuilds map -> reloads fact -> (only on success) swaps the
   P21 passthrough view. On ANY failure the restored ORIGINAL P21 view is left in
   place, so reports stay CORRECT (just slow) — never a broken state.
   Requires: the executing account has DDL rights in P21.
   ============================================================================ */
USE ASI_ReportCache;
GO
CREATE OR ALTER PROCEDURE dbo.uspRefreshFiveWaySalesFact
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        /* 1) rebuild the salesrep->manager memo map.
              Calls the P21 UDFs ONCE per distinct (salesrep, commission_class) pair
              (~505), not per row. Key columns are base-derived, so the empty/stale
              map during this SELECT does not affect them. */
        TRUNCATE TABLE dbo.SalesrepManagerMap;
        INSERT INTO dbo.SalesrepManagerMap (salesrep_id_varchar, commission_class_id, manager_id, manager_name)
        SELECT p.salesrep_id_varchar, p.commission_class_id,
               COALESCE((SELECT c.id FROM P21.dbo.contacts c
                         WHERE c.id = P21.dbo.kb_fn_get_sales_manager(
                                          CONVERT(INT, p.salesrep_id_varchar), p.commission_class_id, NULL)), '0'),
               COALESCE(P21.dbo.kb_fn_get_sales_manager_names(
                            CONVERT(INT, p.salesrep_id_varchar), p.commission_class_id, NULL), 'None')
        FROM (SELECT DISTINCT salesrep_id_varchar, commission_class_id
              FROM dbo.FiveWaySalesCompute) p;

        /* 2) reload the fact (TRUNCATE keeps the columnstore; TABLOCK = bulk load) */
        TRUNCATE TABLE dbo.FiveWaySalesFact;
        INSERT INTO dbo.FiveWaySalesFact WITH (TABLOCK)
        SELECT * FROM dbo.FiveWaySalesCompute;

        /* sanity floor — tune to expected DW volume (Play had ~3.6M) */
        DECLARE @rows BIGINT = (SELECT COUNT_BIG(*) FROM dbo.FiveWaySalesFact);
        IF @rows < 1000000
            THROW 50001, 'FiveWaySalesFact below sanity floor; passthrough swap SKIPPED.', 1;

        /* 3) point the P21 report view at the fact (re-applied each night because
              the 2:05 restore brings back the ORIGINAL). Executed in P21 context. */
        EXEC P21.sys.sp_executesql
             N'CREATE OR ALTER VIEW dbo.asi_3yr_sales_history_report_view
               AS SELECT * FROM ASI_ReportCache.dbo.FiveWaySalesFact;';

        PRINT CONCAT('uspRefreshFiveWaySalesFact OK — ', @rows, ' rows; passthrough active.');
    END TRY
    BEGIN CATCH
        /* leave the restored ORIGINAL P21 view untouched; bubble error to Agent history */
        DECLARE @m NVARCHAR(2000) = CONCAT('uspRefreshFiveWaySalesFact FAILED (view NOT swapped): ', ERROR_MESSAGE());
        THROW 50002, @m, 1;
    END CATCH
END
GO
