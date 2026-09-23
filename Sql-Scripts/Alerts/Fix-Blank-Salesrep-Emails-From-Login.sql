-- Bulk fix: contacts.email_address IS NULL -> copy from the matched login's
-- users.email_address, using the same contact_id -> nickname -> first_name join
-- established this session. Skips any match whose login is delete-flagged (Y) --
-- per the request, those are left alone rather than trusted as a source.
--
-- Scope is deliberately narrow: NULL contacts only, not the WRONG DOMAIN
-- (@alltileccs.com) population -- that's a separate, larger decision still open.
-- Also scoped to contacts.salesrep = 'Y' (confirmed 2026-09-23: real char column,
-- 189 contacts flagged Y, 54087 NULL, 1 N) -- the authoritative "is this actually
-- a salesrep contact" flag, replacing any name-pattern guessing for this script.
--
-- No USE statement -- run this against whichever connection you've already
-- confirmed is correct (there's been more than one environment mixup this
-- session, so double-check your connection before running).

-- 1) Preview -- exactly what would change, before touching anything.
;WITH matched AS (
    SELECT
        c.id AS contact_id,
        c.first_name + ' ' + c.last_name AS salesrep_name,
        c.email_address AS current_email,
        u.email_address AS new_email,
        u.delete_flag AS login_delete_flag,
        CASE WHEN u.name LIKE '%** LEFT%' THEN 'MARKED DEPARTED' ELSE NULL END AS login_departed_marker
    FROM contacts c
    LEFT JOIN contacts_ud cud ON cud.id = c.id
    OUTER APPLY (
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
    WHERE c.email_address IS NULL
      AND c.salesrep = 'Y'
)
SELECT *,
       CASE WHEN new_email NOT LIKE '%@allsurfaces.com' THEN 'HEADS UP: source is not @allsurfaces.com either' ELSE NULL END AS domain_flag
FROM matched
WHERE new_email IS NOT NULL
  AND (login_delete_flag IS NULL OR login_delete_flag <> 'Y')
ORDER BY salesrep_name;

-- 2) The update itself -- review the preview above before running this.
BEGIN TRANSACTION;

;WITH matched AS (
    SELECT
        c.id AS contact_id,
        u.email_address AS new_email,
        u.delete_flag AS login_delete_flag
    FROM contacts c
    LEFT JOIN contacts_ud cud ON cud.id = c.id
    OUTER APPLY (
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
    WHERE c.email_address IS NULL
      AND c.salesrep = 'Y'
)
UPDATE contacts
SET email_address = matched.new_email
FROM contacts
JOIN matched ON matched.contact_id = contacts.id
WHERE matched.new_email IS NOT NULL
  AND (matched.login_delete_flag IS NULL OR matched.login_delete_flag <> 'Y');

SELECT @@ROWCOUNT AS rows_updated;  -- compare against the preview's row count above

-- 3) Verify before committing.
SELECT id, first_name, last_name, email_address
FROM contacts
WHERE id IN (38105, 38109, 38108, 38113, 38120, 38106, 38119, 38111, 38116, 38115, 50512, 38118)
ORDER BY last_name;

-- 4) Only after confirming rows_updated matches the preview and the verify looks right:
-- COMMIT TRANSACTION;

-- If anything looks wrong, instead run:
-- ROLLBACK TRANSACTION;
