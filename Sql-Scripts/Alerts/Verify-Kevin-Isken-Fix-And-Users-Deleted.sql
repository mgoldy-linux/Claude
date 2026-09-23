-- Follow-up on Audit-Salesrep-Email-Domain.sql (2026-09-16)
-- 1) Confirm which Kevin Isken contact_id real orders actually reference
--    (the email fix was applied to 1049, but 24809 -- the one with 88,727 orders
--    of history -- still shows kisken@alltileccs.com)
-- 2) Add users.delete_flag / departed-employee marker to the audit, per request

-- 1) Which contact_id does the actual failing order reference?
--    CORRECTED: 6149652 is Nick Kessler's order (the blank "Sales Rep <>" one).
--    The Kevin Isken / alltileccs.com issue is order 6149016.
SELECT ohs.order_number, ohs.salesrep_id, ohs.primary_salesrep,
       c.id AS contact_id, c.first_name, c.last_name, c.email_address
FROM oe_hdr_salesrep ohs
JOIN contacts c ON c.id = ohs.salesrep_id
WHERE ohs.order_number = 6149016;

-- 1b) And more broadly: which of the two Kevin Isken contact_ids is still being
--     used on NEW orders (last 30 days) -- confirms whether 24809 is still live
--     or whether new orders have already migrated to 1049 on their own.
SELECT c.id AS contact_id, c.email_address, COUNT(*) AS orders_last_30d, MAX(oh.order_date) AS most_recent_order
FROM oe_hdr_salesrep ohs
JOIN oe_hdr oh ON oh.order_no = ohs.order_number
JOIN contacts c ON c.id = ohs.salesrep_id
WHERE ohs.salesrep_id IN (24809, 1049)
  AND ohs.primary_salesrep = 'Y'
  AND oh.order_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY c.id, c.email_address;

-- 2) Schema discovery: how (if at all) do contacts and users link?
--    Don't assume a FK name -- check what's actually there first.
--    CONFIRMED this session: users.contact_id -> contacts.id is the real FK
--    (contacts.login_id / contacts.ads_user also exist but contact_id is the direct link).
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE (TABLE_NAME = 'users' AND COLUMN_NAME LIKE '%contact%')
   OR (TABLE_NAME = 'contacts' AND (COLUMN_NAME LIKE '%login%' OR COLUMN_NAME LIKE '%user%'))
   OR (TABLE_NAME = 'users' AND COLUMN_NAME IN ('id', 'name', 'email_address', 'delete_flag', 'active'));

-- 2b) Real link: users.contact_id -> contacts.id.
--     A contact with no matching login is normal (most salesreps never log into P21
--     directly) -- NULL user_login_id below just means no login exists, not a problem.
SELECT
    c.id AS contact_id, c.first_name, c.last_name, c.email_address AS contact_email,
    u.id AS user_login_id, u.name AS user_name, u.active AS user_active,
    u.delete_flag,
    CASE WHEN u.name LIKE '%** LEFT%' THEN 'MARKED DEPARTED' ELSE NULL END AS departed_marker
FROM contacts c
LEFT JOIN users u ON u.contact_id = c.id
WHERE c.id IN (24809, 1049, 38117, 1052); -- the flagged/anomalous rows from this session

-- 3) Is there a general/shared sales mailbox already defined anywhere in P21
--    that could serve as a fallback recipient for blank/departed reps?
SELECT setting_name, setting_value
FROM system_setting
WHERE setting_name LIKE '%email%' OR setting_name LIKE '%sales%'
ORDER BY setting_name;
