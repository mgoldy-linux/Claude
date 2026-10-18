-- SA 57068: retire KB/JS-era index KBJS_audit_trail_Cover01 on P21.dbo.audit_trail (Prod, SQL Server 2019 Standard)
-- Usage review 10/15/2026 (Prod): see Deploy-Guides/SA-57068-purchasing-open-bo-age-portal.md
--   * only reader found = the v1 asi_fn_purchasing_open_bo_age hint; function v2 (no hint) deployed 10:00 AM, last index seek 9:59:58 AM
--   * 35 cached plans list it: all P21 audit WRITE procs/triggers (index maintenance, 282M updates since 9/20); 0 plans read it
--   * no SQL module, SQL Agent step, or SSRS .rdl (C:\SSRS-Local) names it. Archive job filters date_created only (index leads with source_area_cd).
--   * index is 12.33 GB, nonclustered, no compression, no filter.
-- NOT run. Run the DROP only after Mark OKs it.

-- 0) before: confirm nothing has read it since v2
SELECT i.name, u.user_seeks, u.user_scans, u.user_lookups, u.last_user_seek, u.last_user_scan, u.user_updates
FROM sys.indexes i LEFT JOIN sys.dm_db_index_usage_stats u ON u.object_id=i.object_id AND u.index_id=i.index_id AND u.database_id=DB_ID()
WHERE i.object_id=OBJECT_ID('dbo.audit_trail') AND i.name='KBJS_audit_trail_Cover01'

-- 1) retire
DROP INDEX KBJS_audit_trail_Cover01 ON dbo.audit_trail

-- ROLLBACK (rebuild takes a long time on 171M rows; Standard edition = no ONLINE; blocks audit_trail writes while it builds -> maintenance window only)
-- CREATE NONCLUSTERED INDEX KBJS_audit_trail_Cover01
--     ON dbo.audit_trail (source_area_cd, key1_cd, column_changed, date_created)
--     INCLUDE (key1_value)
