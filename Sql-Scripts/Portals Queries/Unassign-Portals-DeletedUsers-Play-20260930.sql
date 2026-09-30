/* =============================================================================
   Unassign portals from ALL deleted users (delete_flag='Y') -- re-run
   Instance : P21Play  (P21Dev.allsurfaces.com)  -- TEST FIRST, then promote
   Author   : mgoldyn
   Date     : 2026-09-30
   Context  : Same fix as Unassign-Portals-DeletedUsers-Play.sql (2026-06-22,
              ~698 rows / 149 users, committed at the time) -- but Play has
              been refreshed from Prod since then, which restores the DB
              FROM Prod, so a fix that only ever lived in Play does not
              survive. Confirmed today via the KBENISH single-user test:
              her 125 direct portal_assignment rows were still row_status_flag
              704 despite the June fix supposedly covering her.
   Action   : Soft-delete (row_status_flag 704 -> 705) every DIRECT portal
              assignment (role_uid IS NULL) whose user_id is a deleted P21
              user (users.delete_flag = 'Y'). Reversible.
   Scope note: DIRECT assignments only (role_uid IS NULL). Role-based portal
              access (role_uid NOT NULL) for a deleted user's role membership
              is NOT touched here -- separate check if that matters.
   IMPORTANT: For this to survive the next refresh, it also needs to be
              applied to Prod (as row_status_flag = 705, same "deploy
              inactive" pattern used for not-yet-approved changes). Testing
              here in Play first; do not skip the Prod step once verified.
   ============================================================================= */
USE P21Play;
SET NOCOUNT ON;

/* ---- 0. How big is this today? -------------------------------------------- */
SELECT COUNT(DISTINCT u.id) AS deleted_users_with_active_portals,
       COUNT(*)             AS rows_in_scope
FROM portal_assignment pa
JOIN users u ON u.id = pa.user_id
WHERE pa.role_uid IS NULL
  AND u.delete_flag = 'Y'
  AND pa.row_status_flag = 704;

/* ---- 1. Back up the exact rows to be changed ------------------------------ */
IF OBJECT_ID('dbo.asi_portal_assignment_deluser_bak_20260930') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_deluser_bak_20260930;

SELECT pa.*
INTO dbo.asi_portal_assignment_deluser_bak_20260930
FROM portal_assignment pa
JOIN users u ON u.id = pa.user_id
WHERE pa.role_uid IS NULL
  AND u.delete_flag = 'Y'
  AND pa.row_status_flag = 704;

PRINT 'Backed up rows: ' + CAST(@@ROWCOUNT AS varchar(10));

/* ---- 2. Soft-delete (unassign) -------------------------------------------- */
BEGIN TRAN;

UPDATE pa
SET pa.row_status_flag    = 705,
    pa.date_last_modified = GETDATE(),
    pa.last_maintained_by = 'mgoldyn'
FROM portal_assignment pa
JOIN users u ON u.id = pa.user_id
WHERE pa.role_uid IS NULL
  AND u.delete_flag = 'Y'
  AND pa.row_status_flag = 704;

PRINT 'Unassigned (704->705) rows: ' + CAST(@@ROWCOUNT AS varchar(10));

-- Review the PRINT output, then COMMIT (or ROLLBACK to abort):
-- COMMIT TRAN;
-- ROLLBACK TRAN;

/* =============================================================================
   ROLLBACK (run later if needed) -- restores row_status_flag from the bak table:

   USE P21Play;
   UPDATE pa
   SET pa.row_status_flag    = b.row_status_flag,
       pa.date_last_modified = b.date_last_modified,
       pa.last_maintained_by = b.last_maintained_by
   FROM portal_assignment pa
   JOIN dbo.asi_portal_assignment_deluser_bak_20260930 b
        ON b.portal_assignment_uid = pa.portal_assignment_uid;
   ============================================================================= */
