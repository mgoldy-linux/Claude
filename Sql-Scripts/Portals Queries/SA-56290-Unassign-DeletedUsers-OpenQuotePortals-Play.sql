/* =============================================================================
   SA 56290 - Unassign DELETED users from the Open Quote portals
   Instance : P21Play  (P21Dev.allsurfaces.com)  -- TEST FIRST, then promote
   Author   : mgoldyn
   Date     : 2026-10-08
   Context  : Matt asked which roles/users have the open quote portals (SA 56290,
              expired-quote cancel job). Prod check found 23 DIRECT portal
              assignments on the quote portals: 10 on 7 current users, and 13 on
              5 deleted users (DMUSICK, RGERLACH, KBENISH, LBERRY, RGUDERJAHN).
   Action   : Soft-delete (row_status_flag 704 -> 705) the DIRECT assignments
              (role_uid IS NULL) of DELETED users (delete_flag = 'Y') on any
              portal that contains one of the quote elements below. Reversible.
              Never a hard DELETE (FK from portal_param_value; see 9/30 note).
   Scope    : Deleted users only, limited to the 5 Prod-deleted IDs above. The
              user list is hard-coded on purpose: Play's users.delete_flag is
              stale vs Prod (MMAY, MPERRY, TBONAFEDE read 'Y' in Play but are
              current in Prod), so delete_flag alone would hit current users.
              TBASIC (deleted in Play, on BR SAL OPEN QUOTES + ORDERS) is not
              in the Prod list - check him in Prod before adding.
              Current-user rows and ALL role-based assignments are NOT touched.
              Play expected: ~10 rows (KBENISH was already unassigned 9/30).
   Elements : Resolved BY NAME - portal_element_uid is not aligned across
              instances (Play vs Prod).
   Survive refresh: Play is overwritten from Prod on refresh - apply the same
              change to Prod (as 705) once verified here.
   ============================================================================= */
USE P21Play;
SET NOCOUNT ON;

/* ---- 0. Quote portals (via the quote elements) and rows in scope ----------- */
IF OBJECT_ID('tempdb..#quote_portals') IS NOT NULL DROP TABLE #quote_portals;
SELECT DISTINCT pxe.portal_uid
INTO   #quote_portals
FROM   portal_element pe
JOIN   portal_x_portal_element pxe ON pxe.portal_element_uid = pe.portal_element_uid
WHERE  pe.portal_element_name IN ('Open quotes', 'Open service quotes', 'CRM MY OPEN QUOTES',
                                  'MY OPEN QUOTES', 'BR SAL OPEN QUOTE', 'OPEN QUOTES SEARCH');

PRINT 'Quote portals found: ' + CAST(@@ROWCOUNT AS varchar(10)) + '  (Prod: 6 portal rows incl. ORDERS)';

SELECT p.portal_name, u.id AS user_id, u.name, pa.portal_assignment_uid, pa.row_status_flag
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   portal p          ON p.portal_uid  = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y' AND u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN') AND pa.row_status_flag = 704
ORDER BY p.portal_name, u.id;

/* ---- 1. Back up the exact rows to be changed (idempotent) ------------------ */
IF OBJECT_ID('dbo.asi_portal_assignment_quote_deluser_bak_20261008') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_quote_deluser_bak_20261008;

SELECT pa.*
INTO   dbo.asi_portal_assignment_quote_deluser_bak_20261008
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y' AND u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN') AND pa.row_status_flag = 704;

DECLARE @expected int = @@ROWCOUNT;
PRINT 'Backed up rows: ' + CAST(@expected AS varchar(10)) + '  (Play expected ~10; Prod showed 13)';

/* ---- 2. Soft-delete (unassign); commits only if the count matches ---------- */
BEGIN TRAN;

UPDATE pa
SET    pa.row_status_flag    = 705,
       pa.date_last_modified = GETDATE(),
       pa.last_maintained_by = 'mgoldyn'
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y' AND u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN') AND pa.row_status_flag = 704;

DECLARE @changed int = @@ROWCOUNT;
PRINT 'Unassigned (704->705) rows: ' + CAST(@changed AS varchar(10));

IF @changed = @expected AND @changed > 0
BEGIN
    COMMIT TRAN;
    PRINT 'COMMITTED.';
END
ELSE
BEGIN
    ROLLBACK TRAN;
    PRINT 'ROLLED BACK - changed rows did not match the backup count.';
END

/* ---- 3. Verify: should return 0 deleted-user rows still active ------------- */
SELECT COUNT(*) AS deleted_user_rows_still_active
FROM   portal_assignment pa
JOIN   #quote_portals qp ON qp.portal_uid = pa.portal_uid
JOIN   users u           ON u.id = pa.user_id
WHERE  pa.role_uid IS NULL AND u.delete_flag = 'Y' AND u.id IN ('DMUSICK','RGERLACH','KBENISH','LBERRY','RGUDERJAHN') AND pa.row_status_flag = 704;

/* =============================================================================
   ROLLBACK (run later if needed) - restores from the backup table:

   USE P21Play;
   UPDATE pa
   SET pa.row_status_flag    = b.row_status_flag,
       pa.date_last_modified = b.date_last_modified,
       pa.last_maintained_by = b.last_maintained_by
   FROM portal_assignment pa
   JOIN dbo.asi_portal_assignment_quote_deluser_bak_20261008 b
        ON b.portal_assignment_uid = pa.portal_assignment_uid;
   ============================================================================= */
