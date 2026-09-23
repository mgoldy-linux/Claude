-- Checking two things before changing the audit queries' join logic:
-- 1) Does 'users' actually have first_name/last_name columns to join on
--    (contacts.first_name/last_name = users.first_name/last_name), as a
--    supplement/fallback to users.contact_id (which may be sparsely populated)?
-- 2) What IS pc_user_def, and does it cover the same population (salesreps) or
--    a different one (e.g. Physical Count module users -- 'pc_' is a common P21
--    module prefix, not necessarily "the" users table)?

-- 1) Full 'users' schema -- confirm first_name/last_name exist before joining on them.
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'users'
ORDER BY ORDINAL_POSITION;

-- 2) Full pc_user_def schema + what table/view names contain 'pc_user' to see if
--    this is a distinct module's user list, not general P21 login accounts.
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'pc_user_def'
ORDER BY ORDINAL_POSITION;

SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE 'pc_user%' OR TABLE_NAME LIKE '%pc\_%' ESCAPE '\';

-- 3) For the known salesreps from this session, compare contact_id-join vs
--    name-join vs pc_user_def -- do the two 'users' join methods agree, and does
--    pc_user_def even contain these people at all?
SELECT c.id AS contact_id, c.first_name, c.last_name,
       u_by_id.id AS user_via_contact_id, u_by_id.email_address AS email_via_contact_id,
       u_by_name.id AS user_via_name, u_by_name.email_address AS email_via_name,
       pud.user_id AS pc_user_def_user_id, pud.email_address AS pc_user_def_email, pud.active_ind
FROM contacts c
LEFT JOIN users u_by_id ON u_by_id.contact_id = c.id
LEFT JOIN users u_by_name ON u_by_name.first_name = c.first_name AND u_by_name.last_name = c.last_name
LEFT JOIN pc_user_def pud ON pud.first_name = c.first_name AND pud.last_name = c.last_name
WHERE c.id IN (1045, 1049, 1061, 38117, 1052); -- Anthony Basic, Kevin Isken, Herm Claussen, Nick Kessler, Steven Johnson
