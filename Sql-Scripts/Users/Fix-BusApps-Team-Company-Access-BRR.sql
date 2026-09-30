-- Add missing company access (company_id 1) for Business Apps team logins in P21BusinessRules
-- Source: Check-BusApps-Team-Role-Access.sql section 2 -- CSKELTON, EREYES, MMUNSON, TTHOUSAND
-- have no users_x_company row in BRR; MGOLDYN / JVADAKKEL / MLEARNED have company 1.
-- Insert pattern copied from asi_proc_copy_p21_user.sql (users_x_company: company_id, user_id,
-- date_created, date_last_modified, last_maintained_by).
--
-- NOT touched: users.delete_flag (Chad/Efrain stay deleted -- BRR refresh from Prod restores them;
-- see Undelete note in reference_business_apps_team_roster memory), users.active, role.
-- Run in P21BusinessRules ONLY. Rolls back unless the row count matches the preview.

USE P21BusinessRules;
GO

DECLARE @Fix TABLE (login_id varchar(30));
INSERT @Fix VALUES ('CSKELTON'), ('EREYES'), ('MMUNSON'), ('TTHOUSAND');

-- 1) Preview: logins that exist and lack company 1
SELECT DB_NAME() AS db, f.login_id, u.name, u.delete_flag
FROM @Fix f
JOIN users u ON u.id = f.login_id
WHERE NOT EXISTS (SELECT 1 FROM users_x_company c WHERE c.user_id = f.login_id AND c.company_id = '1');

DECLARE @expected int = (SELECT COUNT(*) FROM @Fix f
                         JOIN users u ON u.id = f.login_id
                         WHERE NOT EXISTS (SELECT 1 FROM users_x_company c
                                           WHERE c.user_id = f.login_id AND c.company_id = '1'));

BEGIN TRAN;

INSERT INTO users_x_company (company_id, user_id, date_created, date_last_modified, last_maintained_by)
SELECT '1', f.login_id, GETDATE(), GETDATE(), SYSTEM_USER
FROM @Fix f
JOIN users u ON u.id = f.login_id
WHERE NOT EXISTS (SELECT 1 FROM users_x_company c WHERE c.user_id = f.login_id AND c.company_id = '1');

IF @@ROWCOUNT <> @expected
BEGIN
    PRINT 'Row count mismatch -- rolling back.';
    ROLLBACK TRAN;
END
ELSE
BEGIN
    SELECT DB_NAME() AS db, user_id, company_id
    FROM users_x_company
    WHERE user_id IN (SELECT login_id FROM @Fix);
    COMMIT TRAN;
    PRINT 'Committed.';
END
GO
