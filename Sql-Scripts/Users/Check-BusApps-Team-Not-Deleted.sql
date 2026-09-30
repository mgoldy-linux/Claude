-- Verify Business Apps team P21 logins are NOT deleted (Todo-BusApps #11)
-- Run in each of: P21Play, P21BusinessRules, P21Dev, P21Training (DB_NAME() column labels the output).
-- Team: Mark, Chad, Jossy, Mike, Efrain, Matt.
--
-- Schema confirmed in Verify-Kevin-Isken-Fix-And-Users-Deleted.sql:
--   users.id (login), users.name, users.active, users.delete_flag, users.contact_id -> contacts.id
--
-- Only Mark's surname is known, so this matches on FIRST NAME and returns every candidate
-- (deleted or not). Eyeball the rows, then tighten @Logins below to the exact login ids
-- and use section 2 as the pass/fail check.

-- 1) Candidate discovery: every login/contact whose first name matches a team member
SELECT DB_NAME() AS db,
       u.id AS login_id, u.name AS user_name, c.first_name, c.last_name,
       c.email_address, u.active, u.delete_flag,
       CASE WHEN u.name LIKE '%** LEFT%' THEN 'MARKED DEPARTED' END AS departed_marker
FROM users u
LEFT JOIN contacts c ON c.id = u.contact_id
WHERE c.first_name IN ('Mark', 'Chad', 'Mike', 'Michael', 'Efrain', 'Matt', 'Matthew')
   OR c.first_name LIKE 'Joss%'
   OR u.name LIKE 'Mark Goldyn%' OR u.id IN ('mgoldyn', 'a-mgoldyn')
ORDER BY c.first_name, c.last_name, u.id;

-- 2) Pass/fail: fill in the exact login ids once section 1 identifies them.
--    'MISSING' = no such login in this DB; 'DELETED' = delete_flag = 'Y'.
DECLARE @Logins TABLE (login_id varchar(255));
INSERT @Logins VALUES
    ('CSKELTON'), ('EREYES'),('MLEARNED'), ('MMUNSON'), ('TTHOUSAND'), ('JVADAKKEL')
;

SELECT DB_NAME() AS db, l.login_id,
       u.name AS user_name, u.active, u.delete_flag,
       CASE WHEN u.id IS NULL        THEN 'MISSING'
            WHEN u.delete_flag = 'Y' THEN 'DELETED'
            WHEN u.active <> 'Y'     THEN 'INACTIVE'
            ELSE 'OK' END AS status
FROM @Logins l
LEFT JOIN users u ON u.id = l.login_id
ORDER BY status DESC, l.login_id;
