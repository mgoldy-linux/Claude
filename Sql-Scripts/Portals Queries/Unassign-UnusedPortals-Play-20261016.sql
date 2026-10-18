/* =============================================================================
   Unassign UNUSED portals from roles AND users  (step 1 of portal retirement)
   Instance : P21Play (P21Dev.allsurfaces.com) -- TEST FIRST, then Prod
   Author   : mgoldyn      Date: 2026-10-16
   Basis    : XE-Portal-Usage-Detail.xlsx (2026-05-12..10-16) + XE-Portal-Tab-Detail-Prod.xlsx
              (2026-06-22..10-16). Portal listed = every tab is a custom DataWindow with
              zero opens in both logs. Portals matched BY NAME (uids differ per env).
   Action   : portal_assignment.row_status_flag 704 -> 705 for ROLE rows (role_uid NOT NULL)
              and DIRECT user rows (role_uid NULL). Reversible. NEVER hard DELETE (FK to
              portal_param_value). Portal / portal_element / .srd files are NOT touched.
   Groups   : hold = 1 -> possible seasonal (MLYL, sale day, Saturday, tariff); skipped unless
              @IncludeHold = 1.
   Safety   : @Commit = 0 (default) = dry run -> shows counts, ROLLS BACK. Set @Commit = 1 to keep.
   Refresh  : a Play-only change is wiped by the next refresh from Prod -- must be applied to
              Prod (as 705) to stick. Prod run needs sign-off first.
   ============================================================================= */
USE P21Play;
SET NOCOUNT ON; SET XACT_ABORT ON;
DECLARE @Commit bit = 0, @IncludeHold bit = 0;

IF OBJECT_ID('tempdb..#unused') IS NOT NULL DROP TABLE #unused;
CREATE TABLE #unused (portal_name varchar(255) NOT NULL, hold bit NOT NULL);
INSERT INTO #unused (portal_name, hold) VALUES
    (N'AP VOUCHERS BY CORP VENDOR', 0),
    (N'AR ADJUSTMENTS BY ANALYST', 0),
    (N'AR INVOICES REBILLED FREE', 0),
    (N'AR OPEN RMAS CRCL', 0),
    (N'AR ORDER MARGINS 2DAYS', 0),
    (N'AR ORDER MARGINS 2DAYS SAMPLES ONLY', 0),
    (N'AR ORDERS RELEASED SATURDAY', 1),
    (N'AR RELEASED FROM CREDIT HOLD', 0),
    (N'AR RMAS CANCELLED WITH AMT DUE', 0),
    (N'BACKORDER FILLS SINCE YESTERDAY', 0),
    (N'BR OPEN PT WEIGHTS CARDINAL', 0),
    (N'BR SAL SALE DAY ORDERS EXTENDED ALL', 1),
    (N'COMMISSIONRULE TAB WHAT REPS', 0),
    (N'CRM OPEN OPPTIES MINE', 0),
    (N'CRM OPEN QUOTES MINE', 0),
    (N'CSR CONFL OPEN BO REQ DUE DATES', 0),
    (N'CSR CPL OPEN BO REQ DUE DATES', 0),
    (N'CSR DIRECT ORDERS ALL', 0),
    (N'CSR OPEN BO FILLING NEXT 3D', 0),
    (N'CSR OPEN BO SIG REQ', 0),
    (N'CSR OPEN ORDERS MISSED TARIFF SHIP DEADLINE', 1),
    (N'CSR OPEN RMAS NONSAMPLE ORDER TOTAL', 0),
    (N'CSR ORDERACK EMAILS MISSED', 0),
    (N'CSR ROLL UNIT ORDERS', 0),
    (N'EDI INVOICES AND ORDERS', 0),
    (N'FINO ORDERS OPEN', 0),
    (N'INV NEG QTY ISSUES', 0),
    (N'INVENTORY VALUE SMG', 0),
    (N'ORDERS INVOICED AND DELETED', 0),
    (N'PURCH DIRECT ORDERS DEBY', 0),
    (N'SA EDI ORDERS CANCELLED NEEDING APPROVAL', 0),
    (N'SA SALE DAY ORDERS DEADLINE', 1),
    (N'SA SALE DAY ORDERS DEADLINE EXTENDED', 1),
    (N'SALES BY CORP MLYL ALL', 1),
    (N'SALES BY MFG MLYL ALL', 1),
    (N'SALES BY PRODGRP MLYL ALL', 1),
    (N'SALES BY REP MGR MLYL ALL', 1),
    (N'SALES BY REP MLYL ALL', 1),
    (N'SALES BY REP MLYL SM', 1),
    (N'SALES BY SALESMGR MLYL ALL', 1),
    (N'SALES SMG 3MO', 0),
    (N'TRAINING USERS LOGGED IN', 0),
    (N'WHSE OPEN PT', 0),
    (N'WHSE OPEN PT IND', 0),
    (N'WHSE OPEN PT WOOD DALE', 0),
    (N'WHSE OPEN SHIPPING ERROR RMAS', 0),
    (N'WHSE PICK TICKETS WO INVOICES WC SP UPS', 0),
    (N'WHSE RMA RECEIPTS WO INVOICES', 0);

/* ---- 0. Names not found in this environment ---------------------------------- */
SELECT u.portal_name AS not_found_in_this_env
FROM #unused u LEFT JOIN portal p ON p.portal_name = u.portal_name WHERE p.portal_uid IS NULL;

/* ---- 1. Scope ---------------------------------------------------------------- */
SELECT CASE WHEN pa.role_uid IS NULL THEN 'USER' ELSE 'ROLE' END AS level,
       COUNT(*) AS rows_in_scope, COUNT(DISTINCT p.portal_uid) AS portals
FROM portal_assignment pa
JOIN portal p ON p.portal_uid = pa.portal_uid
JOIN #unused u ON u.portal_name = p.portal_name AND (u.hold = 0 OR @IncludeHold = 1)
WHERE pa.row_status_flag = 704
GROUP BY CASE WHEN pa.role_uid IS NULL THEN 'USER' ELSE 'ROLE' END;

/* ---- 2. Backup exact rows ---------------------------------------------------- */
IF OBJECT_ID('dbo.asi_portal_assignment_unused_bak_20261016') IS NOT NULL
    DROP TABLE dbo.asi_portal_assignment_unused_bak_20261016;
SELECT pa.* INTO dbo.asi_portal_assignment_unused_bak_20261016
FROM portal_assignment pa
JOIN portal p ON p.portal_uid = pa.portal_uid
JOIN #unused u ON u.portal_name = p.portal_name AND (u.hold = 0 OR @IncludeHold = 1)
WHERE pa.row_status_flag = 704;
PRINT 'Backed up rows: ' + CAST(@@ROWCOUNT AS varchar(10));

/* ---- 3. Unassign ------------------------------------------------------------- */
BEGIN TRAN;
UPDATE pa
SET pa.row_status_flag = 705, pa.date_last_modified = GETDATE(), pa.last_maintained_by = 'mgoldyn'
FROM portal_assignment pa
JOIN dbo.asi_portal_assignment_unused_bak_20261016 b ON b.portal_assignment_uid = pa.portal_assignment_uid
WHERE pa.row_status_flag = 704;
PRINT 'Unassigned (704->705): ' + CAST(@@ROWCOUNT AS varchar(10));

IF @Commit = 1 BEGIN COMMIT TRAN; PRINT 'COMMITTED.'; END
ELSE BEGIN ROLLBACK TRAN; PRINT 'DRY RUN -- rolled back. Set @Commit = 1 to keep.'; END

/* ROLLBACK LATER (restores flag from backup):
   UPDATE pa SET pa.row_status_flag = b.row_status_flag, pa.date_last_modified = b.date_last_modified,
                 pa.last_maintained_by = b.last_maintained_by
   FROM portal_assignment pa JOIN dbo.asi_portal_assignment_unused_bak_20261016 b
        ON b.portal_assignment_uid = pa.portal_assignment_uid; */
