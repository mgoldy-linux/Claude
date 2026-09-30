/* =============================================================================
   Deleted-user portal-assignment removal -- single-user test, HARD DELETE
   Instance : P21Play  (P21Dev.allsurfaces.com)  -- TEST FIRST, do not run on Prod
   Author   : mgoldyn
   Date     : 2026-09-30
   Context  : Test-Unassign-Portal-KBENISH-Play.sql already soft-deleted these
              125 rows (row_status_flag 704 -> 705, confirmed Inactive in the
              P21 client's Portal View grid). That grid's Row Status dropdown
              also offers "Delete" -- selecting it + Save issues a hard DELETE
              against portal_assignment, it is not a third status-flag value.
              Doing the 125 rows one at a time in the UI (9 grid pages) is not
              practical, so doing the equivalent DELETE here instead, scoped
              to the exact UIDs already captured in the backup table.
   Safety   : Full pre-image already exists in
              dbo.asi_portal_assignment_kbenish_bak_20260930 (the original
              704 rows, captured before the Inactive update). If anything
              needs to come back, INSERT from that table -- see bottom.
   ============================================================================= */
USE P21Play;
SET NOCOUNT ON;

/* ---- 0. FK check -- confirm nothing else references portal_assignment_uid - */
SELECT fk.name AS fk_name,
       OBJECT_NAME(fk.parent_object_id) AS referencing_table,
       c.name AS referencing_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns c ON c.object_id = fkc.parent_object_id AND c.column_id = fkc.parent_column_id
WHERE fk.referenced_object_id = OBJECT_ID('dbo.portal_assignment');

/* ---- 1. Confirm scope: rows in the backup table that are still Inactive --- */
SELECT pa.portal_assignment_uid, pa.user_id, pa.role_uid, pa.row_status_flag
FROM portal_assignment pa
JOIN dbo.asi_portal_assignment_kbenish_bak_20260930 b
     ON b.portal_assignment_uid = pa.portal_assignment_uid
WHERE pa.row_status_flag = 705;

/* ---- 2. Hard delete -- scoped to the backed-up UIDs only ------------------- */
BEGIN TRAN;

DELETE pa
FROM portal_assignment pa
JOIN dbo.asi_portal_assignment_kbenish_bak_20260930 b
     ON b.portal_assignment_uid = pa.portal_assignment_uid
WHERE pa.user_id = 'KBENISH'
  AND pa.role_uid IS NULL
  AND pa.row_status_flag = 705;

PRINT 'Deleted rows: ' + CAST(@@ROWCOUNT AS varchar(10));

-- Review the PRINT output and the SELECTs above, then COMMIT (or ROLLBACK to abort):
-- COMMIT TRAN;
-- ROLLBACK TRAN;

/* =============================================================================
   RESTORE (run later if needed) -- re-inserts the original rows from the backup:

   USE P21Play;
   SET IDENTITY_INSERT portal_assignment ON;
   INSERT INTO portal_assignment (portal_assignment_uid, user_id, role_uid,
       row_status_flag, date_created, created_by, date_last_modified, last_maintained_by)
   SELECT portal_assignment_uid, user_id, role_uid,
       row_status_flag, date_created, created_by, date_last_modified, last_maintained_by
   FROM dbo.asi_portal_assignment_kbenish_bak_20260930 b
   WHERE NOT EXISTS (
       SELECT 1 FROM portal_assignment pa WHERE pa.portal_assignment_uid = b.portal_assignment_uid
   );
   SET IDENTITY_INSERT portal_assignment OFF;
   -- NOTE: verify portal_assignment's actual column list/identity setup before running this --
   -- the backup table was created via SELECT * INTO, so its columns should match, but confirm.
   ============================================================================= */
