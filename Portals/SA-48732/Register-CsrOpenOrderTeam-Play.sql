/*
    SA 48732 - Register 'CSR OPEN ORDER TEAM' portal element in P21Play
    Server: P21Dev.allsurfaces.com   DB: P21Play

    portal_element.portal_element_uid is NOT an identity column -> supply explicitly.
    portal_user_defined.portal_user_defined_uid IS an identity -> let SQL assign it.
    portal_cd = 932 is the constant classifier for all n_cst_pe_user_def elements.

    Idempotent: does nothing if an element with this name already exists.
*/
SET NOCOUNT ON;

DECLARE @name        VARCHAR(255) = 'CSR OPEN ORDER TEAM';
DECLARE @dw          VARCHAR(255) = 'csr_open_order_team';
DECLARE @lib         VARCHAR(255) = '\\ASP21FS1\play\Portals';
DECLARE @user        VARCHAR(255) = 'mgoldyn';
DECLARE @pe_uid      INT;

IF EXISTS (SELECT 1 FROM portal_element WHERE portal_element_name = @name)
BEGIN
    SELECT 'ALREADY EXISTS - no action' AS result,
           portal_element_uid, portal_element_name
    FROM portal_element WHERE portal_element_name = @name;
    RETURN;
END

BEGIN TRAN;

SELECT @pe_uid = MAX(portal_element_uid) + 1 FROM portal_element;

INSERT INTO portal_element
    (portal_element_uid, portal_element_name, classname, row_status_flag,
     date_created, created_by, date_last_modified, last_maintained_by,
     icon_name, portal_cd, report_metadata_uid)
VALUES
    (@pe_uid, @name, 'n_cst_pe_user_def', 704,
     GETDATE(), @user, GETDATE(), @user,
     'gears_32x32.png', 932, NULL);

INSERT INTO portal_user_defined
    (portal_element_uid, datawindow_name, library_file, url, element_type,
     date_created, created_by, date_last_modified, last_maintained_by, bypass_theme)
VALUES
    (@pe_uid, @dw, @lib, NULL, 1054,
     GETDATE(), @user, GETDATE(), @user, 'N');

COMMIT;

SELECT 'CREATED' AS result, pe.portal_element_uid, pe.portal_element_name,
       pe.classname, pe.portal_cd, pud.portal_user_defined_uid,
       pud.datawindow_name, pud.library_file, pud.element_type
FROM portal_element pe
JOIN portal_user_defined pud ON pud.portal_element_uid = pe.portal_element_uid
WHERE pe.portal_element_uid = @pe_uid;

/* ---------------------------------------------------------------
   ROLLBACK (Play only) -- replace <uid> with the uid reported above:
     DELETE FROM portal_user_defined WHERE portal_element_uid = <uid>;
     DELETE FROM portal_element      WHERE portal_element_uid = <uid>;
   --------------------------------------------------------------- */
