-- users has NO first_name/last_name (confirmed -- error on the previous attempt).
-- It DOES have its own salesrep_id / user_salesrep_id / doe_salesrep_id columns,
-- which may be a more direct link to a salesrep's login than contact_id.
-- pc_user_def looks like an unrelated module's own user list (sits next to
-- pc_message_def/pc_window_def/pc_app_def etc.) -- not pursuing it further
-- unless you know it's actually in use.

-- 1) For the 5 people already tracked this session: contact_id join vs. the three
--    salesrep_id-flavored columns on users vs. a name-text match on users.name.
SELECT
    c.id AS contact_id, c.first_name, c.last_name, c.email_address AS contact_email,
    u_by_contact.id AS user_via_contact_id, u_by_contact.email_address AS email_via_contact_id,
    u_by_contact.salesrep_id, u_by_contact.user_salesrep_id, u_by_contact.doe_salesrep_id,
    u_by_name.id AS user_via_name_match, u_by_name.email_address AS email_via_name_match
FROM contacts c
LEFT JOIN users u_by_contact ON u_by_contact.contact_id = c.id
LEFT JOIN users u_by_name ON u_by_name.name LIKE '%' + c.first_name + '%' + c.last_name + '%'
WHERE c.id IN (1045, 1049, 1061, 38117, 1052);

-- 2) Broader check: does users.salesrep_id, as a raw value, actually look like it
--    stores contacts.id (numeric string) or something else entirely (a rep code,
--    blank, etc.)? Sample of populated values.
SELECT TOP 20 id, name, salesrep_id, user_salesrep_id, doe_salesrep_id, contact_id
FROM users
WHERE salesrep_id IS NOT NULL AND salesrep_id <> '';
