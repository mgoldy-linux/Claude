-- Test the Nick Kessler email fix in P21BusinessRules before repeating in Prod.
-- Contact 38117's email is currently blank; his real login (NKESSLER, found via
-- name match since users.contact_id doesn't point back to him) has
-- nkessler@allsurfaces.com on file -- using that confirmed-real address rather
-- than guessing. Scoped to this ONE contact_id, same pattern as the Isken fix.

use [P21BusinessRules]

-- 1) Baseline -- confirm still blank before touching anything.
SELECT id, first_name, last_name, email_address, date_last_modified, last_maintained_by
FROM contacts
WHERE id = 38117;

-- 2) The update itself.
BEGIN TRANSACTION;

UPDATE contacts
SET email_address = 'nkessler@allsurfaces.com'
WHERE id = 38117
  AND (email_address IS NULL OR email_address = '');  -- guards against overwriting a non-blank value that changed since the baseline above

SELECT @@ROWCOUNT AS rows_updated;  -- should be exactly 1

-- 3) Verify before committing.
SELECT id, first_name, last_name, email_address, date_last_modified, last_maintained_by
FROM contacts
WHERE id = 38117;

-- 4) Only after confirming rows_updated = 1 and the verify SELECT looks right:
-- COMMIT TRANSACTION;

-- If anything looks wrong, instead run:
-- ROLLBACK TRANSACTION;
