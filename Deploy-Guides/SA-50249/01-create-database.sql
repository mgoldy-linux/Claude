/* ============================================================================
   SA-50249  Step 01 — create the persistent report-cache database on the DW
   Target: asdwdb01.ahi.local   |   Run ONCE (survives the nightly P21 restore)
   ============================================================================ */

IF DB_ID('ASI_ReportCache') IS NULL
    CREATE DATABASE ASI_ReportCache;
GO

-- Rebuildable cache: no log backups needed, minimal logging for bulk loads.
ALTER DATABASE ASI_ReportCache SET RECOVERY SIMPLE;
GO

/* The P21 passthrough view SELECTs from ASI_ReportCache, so the SSRS principal
   needs a user + SELECT here (cross-DB ownership chaining does not apply).
   NOTE: confirm the actual login the DW-P21 (or the report's) data source uses.
   The DW's "…Alter SSRS" job references the SSRS_Users login, used here. */
USE ASI_ReportCache;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'SSRS_Users')
    CREATE USER [SSRS_Users] FOR LOGIN [SSRS_Users];
GO
GRANT SELECT ON SCHEMA::dbo TO [SSRS_Users];
GO
