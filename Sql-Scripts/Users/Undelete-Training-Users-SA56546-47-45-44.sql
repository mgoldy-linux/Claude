-- Undelete P21 Training logins (SA 56546 Heather Hess, SA 56547 Scott Strosnider,
-- SA 56545 Dave Lambernedis, SA 56544 Amy Dierks)
-- Training will not search for a user whose users.delete_flag = 'Y'.
--
-- NOT touched: users.active, role, users_x_company. Section 1 shows them so you can see
-- whether anything else is missing (e.g. no company 1 row = still no company access).
--
-- Run in P21Training ONLY (catalog name is P21Training, not "Training").
-- Section 1 is read-only. Section 2 rolls back unless every row that is deleted is
-- fixed and all 4 logins exist.

USE P21Training;
GO

-- 1) Before: all 4 should come back. A missing row = the ID guess is wrong.
SELECT DB_NAME() AS db, u.id AS login_id, u.name AS user_name, u.active, u.delete_flag,
       (SELECT COUNT(*) FROM users_x_company c WHERE c.users_id = u.id) AS company_rows
FROM users u
WHERE u.id IN ('HHESS', 'SSTROSNIDER', 'DLAMBERNEDIS', 'ADIERKS')
ORDER BY u.id;
GO

-- 2) Undelete
DECLARE @found int = (SELECT COUNT(*) FROM users
                      WHERE id IN ('HHESS', 'SSTROSNIDER', 'DLAMBERNEDIS', 'ADIERKS'));

IF @found <> 4
BEGIN
    PRINT 'Expected 4 logins to exist, found ' + CAST(@found AS varchar(10)) + ' -- nothing changed.';
END
ELSE
BEGIN
    BEGIN TRAN;

    UPDATE users
    SET delete_flag = 'N'
    WHERE id IN ('HHESS', 'SSTROSNIDER', 'DLAMBERNEDIS', 'ADIERKS')
      AND delete_flag = 'Y';

    PRINT CAST(@@ROWCOUNT AS varchar(10)) + ' row(s) updated.';

    -- After (inside the transaction, before commit)
    SELECT DB_NAME() AS db, id AS login_id, name AS user_name, active, delete_flag
    FROM users
    WHERE id IN ('HHESS', 'SSTROSNIDER', 'DLAMBERNEDIS', 'ADIERKS')
    ORDER BY id;

    IF EXISTS (SELECT 1 FROM users
               WHERE id IN ('HHESS', 'SSTROSNIDER', 'DLAMBERNEDIS', 'ADIERKS')
                 AND delete_flag <> 'N')
    BEGIN
        PRINT 'A login is still deleted -- rolling back.';
        ROLLBACK TRAN;
    END
    ELSE
    BEGIN
        COMMIT TRAN;
        PRINT 'Committed.';
    END
END
GO
