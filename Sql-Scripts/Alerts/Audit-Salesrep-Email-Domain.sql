-- Audit: sales reps whose contact email does NOT end in @allsurfaces.com
-- (follow-up to the alert_queued_mail 1060/1063 investigation -- kisken@alltileccs.com
-- was one instance, fixed 2026-09-16 in Contact Maintenance to kevini@allsurfaces.com.
-- This finds any other reps carrying a non-standard domain, so they don't surface the
-- same way next time an alert fires to them.)

-- 0) Schema sanity check first (per house rule: verify before assuming) --
--    confirms 'contacts' + 'customer' are still the right source tables
--    and email_address is still the right column, before trusting the audit below.
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('contacts', 'customer')
  AND COLUMN_NAME IN ('id', 'email_address', 'first_name', 'last_name', 'salesrep_id', 'delete_flag', 'customer_id');

-- 1) Every salesrep who is CURRENTLY the primary salesrep on at least one live
--    (delete_flag = 'N') customer -- switched 2026-09-23 from all-time order
--    history, which kept flagging reps (e.g. Anthony Basic) forever even after
--    their live customers got reassigned. This is the live/actionable population.
;WITH active_salesreps AS (
    SELECT DISTINCT salesrep_id
    FROM customer
    WHERE delete_flag = 'N'
)
SELECT
    c.id                                            AS contact_id,
    c.first_name + ' ' + c.last_name                AS salesrep_name,
    c.email_address,
    CASE
        WHEN c.email_address IS NULL OR c.email_address = ''      THEN 'BLANK'
        WHEN c.email_address NOT LIKE '%@allsurfaces.com'          THEN 'WRONG DOMAIN'
        ELSE 'OK'
    END                                              AS email_status,
    u.id                                              AS user_login_id,
    u.email_address                                  AS user_login_email,
    u.delete_flag                                    AS login_delete_flag,
    CASE WHEN u.name LIKE '%** LEFT%' THEN 'MARKED DEPARTED' ELSE NULL END AS login_departed_marker,
    cud.nickname                                      AS contacts_ud_nickname,
    uud.salesrep_id                                  AS users_ud_salesrep_id,
    customer_counts.active_customers_assigned
FROM active_salesreps a
JOIN contacts c ON c.id = a.salesrep_id
LEFT JOIN contacts_ud cud ON cud.id = c.id
OUTER APPLY (
    -- users.contact_id is unreliable/sparsely populated (confirmed 2026-09-23:
    -- Kevin Isken's real login KEVINI has contact_id = NULL). Try contact_id
    -- first; fall back to a nickname match (contacts_ud.nickname, e.g. "Rigo"
    -- for Rigoberto Zamudio -- users.name uses the short form, not the formal
    -- contacts.first_name) then a plain first_name match. '* inactive *' is a
    -- real sentinel value in nickname (confirmed 2026-09-23), not a person's
    -- name, so it's excluded from the match attempt.
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
LEFT JOIN users_ud uud ON uud.id = u.id  -- keys off the login id (users.id), NOT contacts.id -- confirmed 2026-09-23
CROSS APPLY (
    SELECT COUNT(*) AS active_customers_assigned
    FROM customer c2
    WHERE c2.salesrep_id = a.salesrep_id
      AND c2.delete_flag = 'N'
) customer_counts
WHERE (c.email_address IS NULL
   OR c.email_address = ''
   OR c.email_address NOT LIKE '%@allsurfaces.com')
  -- House/bucket accounts excluded by name pattern (no dedicated flag column
  -- confirmed yet) -- these are known non-person accounts from prior runs:
  -- "All Surfaces House X", "X House ###", "Walcro ... House ###", "Open <city>",
  -- "Vendor Rep", "( Unassigned )". Heuristic, not a confirmed flag -- if there's
  -- an actual account-type column, tell me and I'll switch to that instead.
  AND c.first_name + ' ' + c.last_name NOT LIKE '%House%'
  AND c.first_name + ' ' + c.last_name NOT LIKE 'Open %'
  AND c.first_name + ' ' + c.last_name NOT LIKE '%Vendor Rep%'
  AND c.first_name + ' ' + c.last_name NOT LIKE '%Unassigned%'
  -- Confirmed 2026-09-23: contacts_ud.nickname = '* inactive *' is a real, deliberate
  -- deactivation marker (Herm Claussen, Open Florczyk, both "Old Rep" entries, Doug
  -- Stewart, Allie Weiss all carry it). Excluded here since these aren't actionable
  -- "current rep needs a fixed email" cases -- they're already deactivated.
  AND (cud.nickname IS NULL OR cud.nickname NOT LIKE '%inactive%')
ORDER BY customer_counts.active_customers_assigned DESC;

-- 2) Confirm the fix: kisken should no longer appear, kevini should now show OK.
SELECT id, first_name, last_name, email_address
FROM contacts
WHERE email_address IN ('kisken@alltileccs.com', 'kevini@allsurfaces.com')
   OR (first_name = 'Kevin' AND last_name = 'Isken');

-- Performance note: customer is typically large and salesrep_id/delete_flag isn't
-- always a covering/composite index target for DISTINCT scans like this. If this
-- runs slow on Prod, check the actual plan (logical reads via the plan cache DMVs, not
-- wall-clock) before assuming an index is missing -- a one-time audit like this doesn't
-- usually justify adding one.
