/* =============================================================================
   SA 56290 - Unassign DELETED users from the Open Quote portals  ** PROD **
   Instance : Prod (P21.allsurfaces.com), database P21
   Author   : mgoldyn
   Date     : 2026-10-08
   Run AFTER : SA-56290-Unassign-DeletedUsers-OpenQuotePortals-Play.sql has been
               run and verified in P21Play.
   Action   : Soft-delete (row_status_flag 704 -> 705) the DIRECT assignments
              (role_uid IS NULL) of 5 deleted users on the portals that contain
              the quote tabs. Reversible. Never a hard DELETE (FK from
              portal_param_value).
   Rows     : Exactly 13 expected (read-only preview 2026-10-08):
                BR SAL OPEN QUOTES    DMUSICK(980)  RGERLACH(1005)
                CRM OPEN QUOTES MINE  KBENISH(858)  LBERRY(1928)  RGUDERJAHN(1755)
                OPEN QUOTES MINE      DMUSICK(991)  KBENISH(857)  LBERRY(1927)
                                      RGERLACH(1003) RGUDERJAHN(1754)
                OPEN QUOTES SEARCH    KBENISH(1201) LBERRY(1970)  RGUDERJAHN(1797)
              If the count is not 13 the script ROLLS BACK and changes nothing.
   Scope    : Direct assignments of those 5 users only. Current-user rows (10 on
              7 users) and ALL role-based assignments are NOT touched.
              This also covers the "Delete-user cleanup" outstanding from the
              9/30 KBENISH work for these portals.
   Commit   : Automatic when the count matches. P21 runs RCSI, so a second SSMS
              session would show the OLD value if a transaction were left open -
              this script never leaves one open.
   ============================================================================= */
USE P21;
SET NOCOUNT ON;

IF DB_NAME() <> 'P21'
BEGIN
    RAISERROR('Wrong database - this script is for P21 (Prod).', 16, 1);
    RETURN;
END

/* ---- 0. Quote portals and the rows in scope -------------------------------- */
IF OBJECT_ID('tempdb..#quote_portals') IS NOT NULL DROP TABLE #quote_portals;
SELECT DISTINCT pxe.portal_uid
INTO   #quote_portals
FROM   portal_element pe
JOIN   portal_x_portal_element pxe ON pxe.portal_element_uid = pe.portal_element_uid
WHERE  pe.portal_element_name IN ('Open quotes', 'Open service quotes', 'CRM MY OPEN QUOTES',
                                  'MY OPEN QUOTES', 'BR SAL OPEN QUOTE', 'OPEN QUOTES SEARCH');

SELECT p.portal_name, u.id AS user_id, u.name, pa.portal_assignment_uid, pa.row_status_flag
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   portal p          ON p.portal_uid  = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y'
  AND  u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN')
  AND  pa.row_status_flag = 704
ORDER BY p.portal_name, u.id;

/* ---- 1. Back up the exact rows to be changed (idempotent) ------------------ */
IF OBJECT_ID('dbo.asi_portal_assignment_quote_deluser_bak_20261008') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_quote_deluser_bak_20261008;

SELECT pa.*
INTO   dbo.asi_portal_assignment_quote_deluser_bak_20261008
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y'
  AND  u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN')
  AND  pa.row_status_flag = 704;

DECLARE @expected int = @@ROWCOUNT;
PRINT 'Backed up rows: ' + CAST(@expected AS varchar(10)) + '  (expected 13)';

/* ---- 2. Soft-delete (unassign); commits only if exactly 13 ----------------- */
BEGIN TRAN;

UPDATE pa
SET    pa.row_status_flag    = 705,
       pa.date_last_modified = GETDATE(),
       pa.last_maintained_by = 'mgoldyn'
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y'
  AND  u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN')
  AND  pa.row_status_flag = 704;

DECLARE @changed int = @@ROWCOUNT;
PRINT 'Unassigned (704->705) rows: ' + CAST(@changed AS varchar(10));

IF @changed = 13 AND @changed = @expected
BEGIN
    COMMIT TRAN;
    PRINT 'COMMITTED.';
END
ELSE
BEGIN
    ROLLBACK TRAN;
    PRINT 'ROLLED BACK - expected 13 rows, got ' + CAST(@changed AS varchar(10)) + '. Nothing changed.';
END

/* ---- 3. Verify: both should be 0 after a commit ---------------------------- */
SELECT COUNT(*) AS deleted_user_rows_still_active
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y'
  AND  u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN')
  AND  pa.row_status_flag = 704;

/* =============================================================================
   ROLLBACK (run later if needed) - restores from the backup table:

   USE P21;
   UPDATE pa
   SET pa.row_status_flag    = b.row_status_flag,
       pa.date_last_modified = b.date_last_modified,
       pa.last_maintained_by = b.last_maintained_by
   FROM portal_assignment pa
   JOIN dbo.asi_portal_assignment_quote_deluser_bak_20261008 b
        ON b.portal_assignment_uid = pa.portal_assignment_uid;
   ============================================================================= */
