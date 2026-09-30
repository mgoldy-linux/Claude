-- Undelete Business Apps team logins in P21BusinessRules (Todo-BusApps #11)
-- Source: Check-BusApps-Team-Not-Deleted.sql / Check-BusApps-Team-Role-Access.sql results (9/30).
-- Only CSKELTON (Chad Skelton) and EREYES (Efrain Reyes) have delete_flag = 'Y', only in P21BusinessRules.
-- Play / Dev / Training: all team logins already delete_flag = 'N'.
--
-- NOT touched: users.active, role, users_x_company (see Fix-BusApps-Team-Company-Access-BRR.sql
-- for the missing company 1 rows -- run that too, or these logins still won't have company access).
--
-- Run in P21BusinessRules ONLY. Rolls back unless exactly 2 rows change.

USE P21BusinessRules;
GO

-- 1) Before
SELECT DB_NAME() AS db, id AS login_id, name AS user_name, active, delete_flag
FROM users
WHERE id IN ('CSKELTON', 'EREYES');

BEGIN TRAN;

UPDATE users
SET delete_flag = 'N'
WHERE id IN ('CSKELTON', 'EREYES')
  AND delete_flag = 'Y';

IF @@ROWCOUNT <> 2
BEGIN
    PRINT 'Expected 2 rows updated -- rolling back.';
    ROLLBACK TRAN;
END
ELSE
BEGIN
    -- 2) After (inside the transaction, before commit)
    SELECT DB_NAME() AS db, id AS login_id, name AS user_name, active, delete_flag
    FROM users
    WHERE id IN ('CSKELTON', 'EREYES');

    COMMIT TRAN;
    PRINT 'Committed.';
END
GO
