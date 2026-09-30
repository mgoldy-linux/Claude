/* =============================================================================
   Deleted-user portal-assignment removal -- single-user test
   Instance : P21Play  (P21Dev.allsurfaces.com)  -- TEST FIRST, do not run on Prod
   Author   : mgoldyn
   Date     : 2026-09-30
   Test user: KBENISH  (departed 01/2025, users.delete_flag = 'Y' -- confirmed
              departed employee, good single-row test case before running the
              full deleted-users sweep)
   Action   : Same pattern as Unassign-Portals-DeletedUsers-Play.sql (Portal
              Cleanup Step 5, bucket-A, 2026-06-22) -- soft-delete
              (row_status_flag 704 -> 705) every DIRECT portal assignment
              (role_uid IS NULL) for this one user_id. Reversible.
   ============================================================================= */
USE P21Play;
SET NOCOUNT ON;

/* ---- 0. Confirm she's actually deleted, and see what's currently assigned -- */
SELECT id, delete_flag, name
FROM users
WHERE id = 'KBENISH';

SELECT pa.portal_assignment_uid, pa.user_id, pa.role_uid, pa.row_status_flag,
       pa.date_last_modified, pa.last_maintained_by
FROM portal_assignment pa
WHERE pa.user_id = 'KBENISH'
  AND pa.role_uid IS NULL
  AND pa.row_status_flag = 704;

/* ---- 1. Back up the exact rows before changing them ----------------------- */
IF OBJECT_ID('dbo.asi_portal_assignment_kbenish_bak_20260930') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_kbenish_bak_20260930;

SELECT pa.*
INTO dbo.asi_portal_assignment_kbenish_bak_20260930
FROM portal_assignment pa
WHERE pa.user_id = 'KBENISH'
  AND pa.role_uid IS NULL
  AND pa.row_status_flag = 704;

PRINT 'Backed up rows: ' + CAST(@@ROWCOUNT AS varchar(10));

/* ---- 2. Soft-delete (unassign) -- single user only ------------------------- */
BEGIN TRAN;

UPDATE pa
SET pa.row_status_flag    = 705,
    pa.date_last_modified = GETDATE(),
    pa.last_maintained_by = 'mgoldyn'
FROM portal_assignment pa
WHERE pa.user_id = 'KBENISH'
  AND pa.role_uid IS NULL
  AND pa.row_status_flag = 704;

PRINT 'Unassigned (704->705) rows: ' + CAST(@@ROWCOUNT AS varchar(10));

-- Review the PRINT output and the SELECTs above, then COMMIT (or ROLLBACK to abort):
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
   JOIN dbo.asi_portal_assignment_kbenish_bak_20260930 b
        ON b.portal_assignment_uid = pa.portal_assignment_uid;
   ============================================================================= */
