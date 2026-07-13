/* =============================================================================
   Unassign portals from DELETED users  (Portal Cleanup To-Do #2 / Step 5, bucket-A)
   Instance : P21Play  (P21Dev.allsurfaces.com)  -- TEST FIRST, then promote
   Author   : mgoldyn
   Date     : 2026-06-22  (session 9)
   Action   : Soft-delete (row_status_flag 704 -> 705) every DIRECT portal
              assignment (role_uid IS NULL) whose user_id is a deleted P21 user
              (users.delete_flag = 'Y').  Reversible. Files are NOT touched, so
              the "inactivate-in-P21-before-moving-srd" ordering rule does NOT apply.
   Snapshot : C:\_P25\Data-Out\CSV\Play-Portal-DeletedUser-Assignments-20260622.csv
   Expected : ~698 rows across 149 deleted users (as of 2026-06-22).
   ============================================================================= */
USE P21;
SET NOCOUNT ON;

/* ---- 1. Back up the exact rows to be changed (idempotent: drop if re-run) ---- */
IF OBJECT_ID('dbo.asi_portal_assignment_deluser_bak_20260622') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_deluser_bak_20260622;

SELECT pa.*
INTO dbo.asi_portal_assignment_deluser_bak_20260622
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
COMMIT TRAN;
-- ROLLBACK TRAN;

/* =============================================================================
   ROLLBACK (run later if needed) — restores row_status_flag from the bak table:

   USE P21;
   UPDATE pa
   SET pa.row_status_flag    = b.row_status_flag,
       pa.date_last_modified = b.date_last_modified,
       pa.last_maintained_by = b.last_maintained_by
   FROM portal_assignment pa
   JOIN dbo.asi_portal_assignment_deluser_bak_20260622 b
        ON b.portal_assignment_uid = pa.portal_assignment_uid;
   ============================================================================= */
