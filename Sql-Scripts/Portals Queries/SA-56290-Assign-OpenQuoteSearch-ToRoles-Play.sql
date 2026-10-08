/* =============================================================================
   SA 56290 - Move the Open Quote portals to ROLE-based assignment
   Instance : P21Play  (P21Dev.allsurfaces.com)  -- TEST FIRST, then promote
   Author   : mgoldyn
   Date     : 2026-10-08
   Goal     : No direct (per-user) assignments on the open quote portals; access
              comes from roles only.
   Step A   : Give the OPEN QUOTES SEARCH portal to these roles (Sales Manager
              already has it; Branch Manager, Outside Sales, Customer Service,
              Customer Service Manager, Purchasing, Management are added):
                 Sales Manager, Branch Manager, Outside Sales, Customer Service,
                 Customer Service Manager, Purchasing, Management
              A role that already has a row for the portal is re-activated
              (705 -> 704) instead of getting a duplicate.
   Step B   : Inactivate (704 -> 705) the DIRECT rows (role_uid IS NULL) of the 7
              current users on OPEN QUOTES MINE / OPEN QUOTES SEARCH /
              BR SAL OPEN QUOTES. After step A each of them still reaches Search
              through their role. Prod had 10 such rows:
                 JKLITZMAN MINE | MLEWIS MINE+SEARCH | TSPENCER MINE+BR SAL |
                 JDAUGHERTY MINE | MMAY MINE+SEARCH | MPERRY SEARCH | TBONAFEDE SEARCH
              (dropped on purpose, near-zero use: Jami MINE, Martin MINE,
              Tasha MINE + BR SAL, Justine MINE - they do not write quotes.)
   Not touched: role-based rows already in place, MINE and BR SAL role rows,
              deleted-user rows (see the separate *-DeletedUsers-* scripts).
   Lookups  : portals and roles are resolved BY NAME; ids differ between
              Play and Prod. Users are matched by id, NOT users.delete_flag
              (Play's flag is stale vs Prod).
   New uids : NEXT VALUE FOR dbo.seq_portal_assignment (P21's own sequence).
   Safety   : Backup tables, one transaction, auto-ROLLBACK on any error or if
              a lookup fails. Soft-delete only, never a hard DELETE.
   ============================================================================= */
USE P21Play;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @search_uid int, @mine_uid int, @brsal_uid int;
SELECT @search_uid = portal_uid FROM portal WHERE portal_name = 'OPEN QUOTES SEARCH';
SELECT @mine_uid   = portal_uid FROM portal WHERE portal_name = 'OPEN QUOTES MINE';
SELECT @brsal_uid  = portal_uid FROM portal WHERE portal_name = 'BR SAL OPEN QUOTES';

IF @search_uid IS NULL OR @mine_uid IS NULL OR @brsal_uid IS NULL
BEGIN
    RAISERROR('A portal name was not found (OPEN QUOTES SEARCH / MINE / BR SAL OPEN QUOTES). Nothing changed.', 16, 1);
    RETURN;
END

/* ---- 0. Target roles and their current state on the Search portal --------- */
IF OBJECT_ID('tempdb..#target_roles') IS NOT NULL DROP TABLE #target_roles;
SELECT r.role_uid, r.role,
       (SELECT COUNT(*) FROM portal_assignment pa WHERE pa.portal_uid = @search_uid
          AND pa.role_uid = r.role_uid AND pa.row_status_flag = 704) AS has_active,
       (SELECT COUNT(*) FROM portal_assignment pa WHERE pa.portal_uid = @search_uid
          AND pa.role_uid = r.role_uid AND pa.row_status_flag <> 704) AS has_inactive
INTO   #target_roles
FROM   roles r
WHERE  r.delete_flag = 'N'
  AND  r.role IN ('Sales Manager','Branch Manager','Outside Sales','Customer Service',
                  'Customer Service Manager','Purchasing','Management');

IF (SELECT COUNT(*) FROM #target_roles) <> 7
BEGIN
    SELECT * FROM #target_roles;
    RAISERROR('Expected 7 target roles, found a different number. Nothing changed.', 16, 1);
    RETURN;
END

PRINT '--- Step A preview: roles for OPEN QUOTES SEARCH';
SELECT role,
       CASE WHEN has_active   > 0 THEN 'already active - skip'
            WHEN has_inactive > 0 THEN 'inactive row - REACTIVATE'
            ELSE 'INSERT new row' END AS action
FROM   #target_roles ORDER BY role;

PRINT '--- Step B preview: direct rows to inactivate';
SELECT p.portal_name, u.id AS user_id, u.name, pa.portal_assignment_uid
FROM   portal_assignment pa
JOIN   portal p ON p.portal_uid = pa.portal_uid
JOIN   users  u ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND pa.row_status_flag = 704
  AND  pa.portal_uid IN (@search_uid, @mine_uid, @brsal_uid)
  AND  u.id IN ('JKLITZMAN','MLEWIS','TSPENCER','JDAUGHERTY','MMAY','MPERRY','TBONAFEDE')
ORDER BY p.portal_name, u.id;

/* ---- 1. Backups (idempotent) ----------------------------------------------- */
IF OBJECT_ID('dbo.asi_portal_assignment_quote_roles_bak_20261008') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_quote_roles_bak_20261008;
IF OBJECT_ID('dbo.asi_portal_assignment_quote_roles_new_20261008') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_quote_roles_new_20261008;

-- rows that will change state (direct rows to inactivate + role rows to reactivate)
SELECT pa.*
INTO   dbo.asi_portal_assignment_quote_roles_bak_20261008
FROM   portal_assignment pa
WHERE  (pa.role_uid IS NULL AND pa.row_status_flag = 704
        AND pa.portal_uid IN (@search_uid, @mine_uid, @brsal_uid)
        AND pa.user_id IN ('JKLITZMAN','MLEWIS','TSPENCER','JDAUGHERTY','MMAY','MPERRY','TBONAFEDE'))
   OR  (pa.portal_uid = @search_uid AND pa.row_status_flag <> 704
        AND pa.role_uid IN (SELECT role_uid FROM #target_roles WHERE has_active = 0));

DECLARE @bak int = @@ROWCOUNT;
PRINT 'Backed up rows: ' + CAST(@bak AS varchar(10));

CREATE TABLE dbo.asi_portal_assignment_quote_roles_new_20261008 (portal_assignment_uid int NOT NULL PRIMARY KEY);

/* ---- 2. Apply, in one transaction ------------------------------------------ */
DECLARE @ins int = 0, @react int = 0, @off int = 0;

BEGIN TRY
    BEGIN TRAN;

    -- A1. reactivate role rows that exist but are inactive
    UPDATE pa
    SET    pa.row_status_flag = 704, pa.date_last_modified = GETDATE(), pa.last_maintained_by = 'mgoldyn'
    FROM   portal_assignment pa
    JOIN   #target_roles t ON t.role_uid = pa.role_uid
    WHERE  pa.portal_uid = @search_uid AND t.has_active = 0 AND t.has_inactive > 0
      AND  pa.row_status_flag <> 704;
    SET @react = @@ROWCOUNT;

    -- A2. insert role rows for roles with no row at all
    INSERT INTO portal_assignment (portal_assignment_uid, portal_uid, user_id, role_uid,
                                   created_by, last_maintained_by, row_status_flag)
    OUTPUT inserted.portal_assignment_uid INTO dbo.asi_portal_assignment_quote_roles_new_20261008
    SELECT NEXT VALUE FOR dbo.seq_portal_assignment, @search_uid, NULL, t.role_uid,
           'mgoldyn', 'mgoldyn', 704
    FROM   #target_roles t
    WHERE  t.has_active = 0 AND t.has_inactive = 0;
    SET @ins = @@ROWCOUNT;

    -- B. inactivate the direct rows of the 7 current users
    UPDATE pa
    SET    pa.row_status_flag = 705, pa.date_last_modified = GETDATE(), pa.last_maintained_by = 'mgoldyn'
    FROM   portal_assignment pa
    WHERE  pa.role_uid IS NULL AND pa.row_status_flag = 704
      AND  pa.portal_uid IN (@search_uid, @mine_uid, @brsal_uid)
      AND  pa.user_id IN ('JKLITZMAN','MLEWIS','TSPENCER','JDAUGHERTY','MMAY','MPERRY','TBONAFEDE');
    SET @off = @@ROWCOUNT;

    PRINT 'A: reactivated ' + CAST(@react AS varchar(10)) + ', inserted ' + CAST(@ins AS varchar(10))
        + ' | B: inactivated ' + CAST(@off AS varchar(10));

    -- every changed/new row must be accounted for; otherwise abort
    IF (@react + @off) <> @bak
        RAISERROR('Changed row count does not match the backup count. Rolling back.', 16, 1);
    IF (@ins + @react) <> (SELECT COUNT(*) FROM #target_roles WHERE has_active = 0)
        RAISERROR('Role rows added do not match the roles that needed one. Rolling back.', 16, 1);

    COMMIT TRAN;
    PRINT 'COMMITTED.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    PRINT 'ROLLED BACK - ' + ERROR_MESSAGE();
END CATCH;

/* ---- 3. Verify -------------------------------------------------------------- */
PRINT '--- OPEN QUOTES SEARCH by role (expect all 7 roles active)';
SELECT r.role, pa.portal_assignment_uid, pa.row_status_flag
FROM   portal_assignment pa JOIN roles r ON r.role_uid = pa.role_uid
WHERE  pa.portal_uid = @search_uid AND r.role IN
       ('Sales Manager','Branch Manager','Outside Sales','Customer Service',
        'Customer Service Manager','Purchasing','Management')
ORDER BY r.role;

PRINT '--- Counter alignment (seq_current should be >= data_max; read-only peek)';
SELECT (SELECT CAST(current_value AS bigint) FROM sys.sequences WHERE name = 'seq_portal_assignment') AS seq_current,
       (SELECT MAX(portal_assignment_uid) FROM portal_assignment)                                      AS data_max;

PRINT '--- Direct rows still active on the 3 portals (expect 0 for the 7 users)';
SELECT COUNT(*) AS direct_rows_still_active
FROM   portal_assignment pa
WHERE  pa.role_uid IS NULL AND pa.row_status_flag = 704
  AND  pa.portal_uid IN (@search_uid, @mine_uid, @brsal_uid)
  AND  pa.user_id IN ('JKLITZMAN','MLEWIS','TSPENCER','JDAUGHERTY','MMAY','MPERRY','TBONAFEDE');

/* =============================================================================
   ROLLBACK (run later if needed):

   USE P21Play;
   -- 1) put changed rows back to their old state
   UPDATE pa
   SET pa.row_status_flag = b.row_status_flag, pa.date_last_modified = b.date_last_modified,
       pa.last_maintained_by = b.last_maintained_by
   FROM portal_assignment pa
   JOIN dbo.asi_portal_assignment_quote_roles_bak_20261008 b
        ON b.portal_assignment_uid = pa.portal_assignment_uid;
   -- 2) turn off the rows this script inserted (soft, not a DELETE)
   UPDATE pa
   SET pa.row_status_flag = 705, pa.date_last_modified = GETDATE(), pa.last_maintained_by = 'mgoldyn'
   FROM portal_assignment pa
   JOIN dbo.asi_portal_assignment_quote_roles_new_20261008 n
        ON n.portal_assignment_uid = pa.portal_assignment_uid;
   ============================================================================= */
