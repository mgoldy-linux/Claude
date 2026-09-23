-- Broader than Audit-Salesrep-Email-Domain.sql: catches malformed/corrupted email
-- values, not just wrong-domain ones. Triggered by contact 38117 (Nick Kessler) --
-- the value on file was 'nkessler@allsurfaces.com>' (stray trailing '>'), which a
-- simple LIKE '%@allsurfaces.com%' domain check would wrongly pass as fine.

-- 1) Re-confirm contact 38117's current state -- did the Contact Maintenance edit
--    actually strip the trailing '>' or was the corrupted value re-saved as-is?
SELECT id, first_name, last_name, email_address, LEN(email_address) AS len,
       CASE WHEN email_address LIKE '%[<>]%' THEN 'STILL HAS < OR >' ELSE 'CLEAN' END AS bracket_check
FROM contacts
WHERE id = 38117;

-- 2) Every salesrep CURRENTLY primary on at least one live customer (same
--    population as the domain audit, switched 2026-09-23 from all-time order
--    history) whose email fails basic format validity -- blank, no '@', stray
--    brackets, embedded semicolon/space (two addresses concatenated), or
--    leading/trailing whitespace.
;WITH active_salesreps AS (
    SELECT DISTINCT salesrep_id
    FROM customer
    WHERE delete_flag = 'N'
)
SELECT
    c.id AS contact_id,
    c.first_name + ' ' + c.last_name AS salesrep_name,
    c.email_address,
    CASE
        WHEN c.email_address IS NULL OR c.email_address = ''            THEN 'BLANK'
        WHEN c.id = 1052                                                THEN 'OK -- confirmed intentional multi-recipient workaround (2026-09-23), not corruption'
        WHEN c.email_address LIKE '%[<>]%'                              THEN 'STRAY BRACKET'
        WHEN c.email_address LIKE '%;%'                                 THEN 'MULTIPLE ADDRESSES CONCATENATED'
        WHEN c.email_address LIKE '% %'                                 THEN 'EMBEDDED SPACE'
        WHEN c.email_address <> LTRIM(RTRIM(c.email_address))           THEN 'LEADING/TRAILING WHITESPACE'
        WHEN c.email_address NOT LIKE '_%@_%.__%'                       THEN 'NOT A VALID EMAIL SHAPE'
        WHEN c.email_address NOT LIKE '%@allsurfaces.com'
             AND c.email_address NOT LIKE '%@alltileccs.com'            THEN 'UNEXPECTED DOMAIN (not allsurfaces or alltileccs)'
        ELSE 'OK'
    END AS issue,
    u.id AS user_login_id,
    u.email_address AS user_login_email,
    u.delete_flag AS login_delete_flag,
    CASE WHEN u.name LIKE '%** LEFT%' THEN 'MARKED DEPARTED' ELSE NULL END AS login_departed_marker,
    cud.nickname AS contacts_ud_nickname,
    uud.salesrep_id AS users_ud_salesrep_id,
    customer_counts.active_customers_assigned
FROM active_salesreps a
JOIN contacts c ON c.id = a.salesrep_id
LEFT JOIN contacts_ud cud ON cud.id = c.id
OUTER APPLY (
    -- users.contact_id is unreliable/sparsely populated (confirmed 2026-09-23).
    -- Try contact_id first; fall back to a nickname match (contacts_ud.nickname,
    -- e.g. "Rigo" for Rigoberto Zamudio -- users.name uses the short form) then
    -- a plain first_name match. '* inactive *' is a real sentinel value in
    -- nickname, not a person's name, so it's excluded from the match attempt.
    SELECT TOP 1 u2.*
    FROM users u2
    WHERE u2.contact_id = c.id
       OR (cud.nickname IS NOT NULL AND cud.nickname NOT LIKE '%inactive%'
           AND u2.name LIKE '%' + cud.nickname + '%' + c.last_name + '%')
       OR u2.name LIKE '%' + c.first_name + '%' + c.last_name + '%'
    ORDER BY
        CASE WHEN u2.contact_id = c.id THEN 0
             WHEN cud.nickname IS NOT NULL AND cud.nickname NOT LIKE '%inactive%'
                  AND u2.name LIKE '%' + cud.nickname + '%' + c.last_name + '%' THEN 1
             ELSE 2 END
) u
LEFT JOIN users_ud uud ON uud.id = u.id  -- keys off the login id (users.id), NOT contacts.id
CROSS APPLY (
    SELECT COUNT(*) AS active_customers_assigned
    FROM customer c2
    WHERE c2.salesrep_id = a.salesrep_id AND c2.delete_flag = 'N'
) customer_counts
WHERE (
    c.email_address IS NULL
    OR c.email_address = ''
    OR c.email_address LIKE '%[<>]%'
    OR c.email_address LIKE '%;%'
    OR c.email_address LIKE '% %'
    OR c.email_address <> LTRIM(RTRIM(c.email_address))
    OR c.email_address NOT LIKE '_%@_%.__%'
  )
  -- House/bucket accounts excluded by name pattern -- see Audit-Salesrep-Email-Domain.sql
  -- for the same heuristic and its caveat (no confirmed dedicated flag column yet).
  AND c.first_name + ' ' + c.last_name NOT LIKE '%House%'
  AND c.first_name + ' ' + c.last_name NOT LIKE 'Open %'
  AND c.first_name + ' ' + c.last_name NOT LIKE '%Vendor Rep%'
  AND c.first_name + ' ' + c.last_name NOT LIKE '%Unassigned%'
  -- Confirmed 2026-09-23: contacts_ud.nickname = '* inactive *' is a real,
  -- deliberate deactivation marker -- excluded as not actionable.
  AND (cud.nickname IS NULL OR cud.nickname NOT LIKE '%inactive%')
ORDER BY
    CASE
        WHEN c.email_address IS NULL OR c.email_address = '' THEN 2  -- blank, lower priority
        ELSE 1                                                        -- actual corruption, higher priority
    END,
    customer_counts.active_customers_assigned DESC;
