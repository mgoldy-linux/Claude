-- Update-UsersUD-SalesrepId.sql
-- Purpose : the ONE sanctioned way to change users_ud.salesrep_id (owner: Mark Goldyn).
--           Edit @Fix, run once as a dry run (@Commit = 0 -> ROLLBACK), review, then set @Commit = 1.
-- Target  : Prod  P21.allsurfaces.com / P21   (also fine in Play)
-- After   : run EXEC dbo.asi_proc_users_ud_salesrep_baseline_refresh so the daily watch accepts the change.
-- Notes   : - UPDATE only. Users with no users_ud row are reported, not inserted (add them in User Maintenance).
--           - NULL new_salesrep_id = clear the field.
--           - users_ud trigger t_users_ud_audit_update_iu stamps last_maintained_by = SYSTEM_USER (you).

SET NOCOUNT ON;
DECLARE @Commit bit = 0;               -- 0 = dry run (rolls back)   1 = commit
DECLARE @AllowDeletedLogins bit = 0;   -- 0 = skip logins with users.delete_flag = 'Y' (default)   1 = allow (separate cleanup pass only)

DECLARE @Fix TABLE (
    id               varchar(30) NOT NULL PRIMARY KEY,   -- users.id (login)
    new_salesrep_id  varchar(16) NULL,                   -- contacts.id of the rep, or NULL to clear
    reason           varchar(200) NOT NULL
);

INSERT @Fix (id, new_salesrep_id, reason) VALUES
 ('CSKELTON', NULL, 'Carries Dean Nagel 1303 - Matt approved clearing in Prod 2026-10-05');
-- ('LOGIN',  '1234', 'why');

-- ---- 1) Preview ------------------------------------------------------------------------------
SELECT f.id, ud.salesrep_id AS current_salesrep_id, f.new_salesrep_id, f.reason,
       CASE WHEN ud.id IS NULL THEN 'NO users_ud ROW - skipped'
            WHEN u.delete_flag = 'Y' AND @AllowDeletedLogins = 0 THEN 'LOGIN IS DELETED - skipped (set @AllowDeletedLogins = 1)'
            WHEN f.new_salesrep_id IS NOT NULL AND NOT EXISTS (
                 SELECT 1 FROM dbo.contacts c WHERE c.id = f.new_salesrep_id AND c.salesrep = 'Y' AND c.delete_flag = 'N')
                 THEN 'NEW ID IS NOT AN ACTIVE REP CONTACT - skipped'
            WHEN ISNULL(ud.salesrep_id,'') = ISNULL(f.new_salesrep_id,'') THEN 'no change'
            ELSE 'WILL UPDATE' END AS action
FROM @Fix f
LEFT JOIN dbo.users_ud ud ON ud.id = f.id
LEFT JOIN dbo.users    u  ON u.id  = f.id;

-- ---- 2) Update (inside a transaction) -----------------------------------------------------------
BEGIN TRAN;

UPDATE ud
SET    ud.salesrep_id = f.new_salesrep_id
FROM   dbo.users_ud ud
JOIN   @Fix f ON f.id = ud.id
JOIN   dbo.users u ON u.id = ud.id
WHERE  ISNULL(ud.salesrep_id,'') <> ISNULL(f.new_salesrep_id,'')
  AND (u.delete_flag <> 'Y' OR @AllowDeletedLogins = 1)
  AND (f.new_salesrep_id IS NULL OR EXISTS (
        SELECT 1 FROM dbo.contacts c WHERE c.id = f.new_salesrep_id AND c.salesrep = 'Y' AND c.delete_flag = 'N'));

PRINT CONCAT('Rows updated: ', @@ROWCOUNT);

SELECT ud.id, ud.salesrep_id AS salesrep_id_after, ud.last_maintained_by, ud.date_last_modified
FROM   dbo.users_ud ud JOIN @Fix f ON f.id = ud.id;

IF @Commit = 1 BEGIN COMMIT; PRINT 'COMMITTED. Now run dbo.asi_proc_users_ud_salesrep_baseline_refresh.'; END
ELSE            BEGIN ROLLBACK; PRINT 'DRY RUN - rolled back. Set @Commit = 1 to apply.'; END

-- ---- 3) Read-only cleanup candidates (not changed by this script) -------------------------------
-- Deleted logins that still carry a salesrep_id (clear them via @Fix if you want them gone).
SELECT ud.id, ud.salesrep_id, ud.last_maintained_by, ud.date_last_modified
FROM   dbo.users_ud ud
JOIN   dbo.users u ON u.id = ud.id
WHERE  u.delete_flag = 'Y' AND ISNULL(ud.salesrep_id,'') <> ''
ORDER BY ud.id;
