-- CREATE-asi_users_ud_salesrep_watch.sql
-- Daily watch on users_ud.salesrep_id. Mark Goldyn is the only person who should change it.
-- Objects (all dbo):
--   asi_users_ud_salesrep_baseline            last accepted value per login
--   asi_view_users_ud_salesrep_changes        rows whose current value differs from baseline (empty = clean)
--   asi_proc_users_ud_salesrep_baseline_refresh   accept current values as the new baseline (owner only)
-- Deploy: P21Play first, then Prod. Prod login's default schema is NOT dbo, so everything is dbo-qualified.

-- 1) Baseline table --------------------------------------------------------------------------------
IF OBJECT_ID('dbo.asi_users_ud_salesrep_baseline','U') IS NULL
CREATE TABLE dbo.asi_users_ud_salesrep_baseline (
    user_id        varchar(30)  NOT NULL CONSTRAINT pk_asi_users_ud_salesrep_baseline PRIMARY KEY,
    salesrep_id    varchar(16)  NULL,
    baseline_date  datetime     NOT NULL CONSTRAINT df_asi_uuds_bl_date DEFAULT (GETDATE()),
    baseline_by    varchar(255) NOT NULL CONSTRAINT df_asi_uuds_bl_by   DEFAULT (SUSER_SNAME())
);
GO

-- 2) Change view -----------------------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.asi_view_users_ud_salesrep_changes
AS
SELECT  COALESCE(ud.id, b.user_id)            AS user_id,
        b.salesrep_id                         AS baseline_salesrep_id,
        ud.salesrep_id                        AS current_salesrep_id,
        CASE WHEN b.user_id IS NULL THEN 'NEW ROW'
             WHEN ud.id     IS NULL THEN 'ROW REMOVED'
             ELSE 'CHANGED' END               AS change_type,
        ud.last_maintained_by,
        ud.date_last_modified,
        CASE WHEN ud.last_maintained_by IN ('AHI\mgoldyn','mgoldyn') THEN 'Y' ELSE 'N' END AS edited_by_owner
FROM    dbo.users_ud ud
FULL JOIN dbo.asi_users_ud_salesrep_baseline b ON b.user_id = ud.id
WHERE   ISNULL(NULLIF(ud.salesrep_id,''),'') <> ISNULL(NULLIF(b.salesrep_id,''),'');
GO

-- 3) Baseline refresh (run after YOUR OWN legitimate change, or after you review a flagged one) ----------
CREATE OR ALTER PROCEDURE dbo.asi_proc_users_ud_salesrep_baseline_refresh
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
        DELETE dbo.asi_users_ud_salesrep_baseline;
        INSERT dbo.asi_users_ud_salesrep_baseline (user_id, salesrep_id)
        SELECT id, salesrep_id FROM dbo.users_ud;
    COMMIT;
    SELECT COUNT(*) AS baseline_rows, SUM(CASE WHEN NULLIF(salesrep_id,'') IS NOT NULL THEN 1 ELSE 0 END) AS with_salesrep_id
    FROM dbo.asi_users_ud_salesrep_baseline;
END
GO

-- 4) Grants: view readable by P21 / SSRS-style readers; proc stays owner-only (no grant) ---------------
GRANT SELECT ON dbo.asi_view_users_ud_salesrep_changes TO p21_application_role, PxxiUser;
GO

-- 5) First-time seed (run once, AFTER the Update-UsersUD-SalesrepId.sql changes are committed) ---------
-- EXEC dbo.asi_proc_users_ud_salesrep_baseline_refresh;

-- 6) Daily check (read-only; any rows = investigate) ------------------------------------------------------
-- SELECT * FROM dbo.asi_view_users_ud_salesrep_changes ORDER BY date_last_modified DESC;

-- Verify landing schema
SELECT s.name AS schema_name, o.name, o.type_desc
FROM sys.objects o JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.name LIKE 'asi[_]%users[_]ud[_]salesrep%';
