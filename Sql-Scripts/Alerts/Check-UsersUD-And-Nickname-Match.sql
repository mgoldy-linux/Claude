-- Two findings to verify before improving the join logic again:
-- 1) users_ud.salesrep_id -- does this table/column exist, and what does it link to?
-- 2) Why RZAMUDIO (contact 21563, Rigoberto Zamudio) wasn't matched by the current
--    contact_id-or-name join, despite having a real login with the correct email
--    (rzamudio@allsurfaces.com, confirmed via User Maintenance screenshot).
--    Theory: users.name uses the NICKNAME ("Rigo"), not contacts.first_name
--    ("Rigoberto") -- contacts_ud.nickname likely holds the short form that
--    actually matches users.name.

-- 1) Schema check: users_ud
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users_ud'
ORDER BY ORDINAL_POSITION;

-- 2) RZAMUDIO specifically -- confirm the nickname theory and what users_ud holds for him.
SELECT
    c.id AS contact_id, c.first_name, c.last_name,
    cud.nickname,
    u.id AS user_login_id, u.name AS user_name, u.email_address AS user_email,
    uud.* -- see whatever columns query 1 reveals
FROM contacts c
LEFT JOIN contacts_ud cud ON cud.id = c.id
LEFT JOIN users u ON u.name LIKE '%' + ISNULL(cud.nickname, c.first_name) + '%' + c.last_name + '%'
LEFT JOIN users_ud uud ON uud.id = c.id  -- guessing the key matches contacts_ud's pattern -- confirm against query 1
WHERE c.id = 21563;

-- 3) Broader check: how many of the currently-unmatched WRONG DOMAIN/BLANK reps
--    get picked up once we also try nickname in the name match? (Run after
--    confirming query 1's real users_ud key/columns -- this may need adjusting.)
;WITH active_salesreps AS (
    SELECT DISTINCT salesrep_id
    FROM customer
    WHERE delete_flag = 'N'
)
SELECT
    c.id AS contact_id, c.first_name, c.last_name, cud.nickname, c.email_address,
    u_by_contact.id AS user_via_contact_id,
    u_by_name.id AS user_via_firstname_match,
    u_by_nickname.id AS user_via_nickname_match
FROM active_salesreps a
JOIN contacts c ON c.id = a.salesrep_id
LEFT JOIN contacts_ud cud ON cud.id = c.id
LEFT JOIN users u_by_contact ON u_by_contact.contact_id = c.id
LEFT JOIN users u_by_name ON u_by_name.name LIKE '%' + c.first_name + '%' + c.last_name + '%'
LEFT JOIN users u_by_nickname ON cud.nickname IS NOT NULL AND u_by_nickname.name LIKE '%' + cud.nickname + '%' + c.last_name + '%'
WHERE c.email_address IS NULL
   OR c.email_address = ''
   OR c.email_address NOT LIKE '%@allsurfaces.com'
ORDER BY c.last_name;
