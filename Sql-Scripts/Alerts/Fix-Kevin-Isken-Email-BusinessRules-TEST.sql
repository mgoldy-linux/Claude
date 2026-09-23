-- Test the Kevin Isken email fix in P21BusinessRules before repeating it in Prod.
-- Mirrors the manual Contact Maintenance edit already done elsewhere (9/16):
-- contact 1049, kisken@alltileccs.com -> kevini@allsurfaces.com.
-- Scoped to this ONE contact_id -- not a domain-wide update -- since only this
-- specific record/person has been confirmed as needing the change.

use [P21BusinessRules]

-- 1) Baseline -- capture the current value before touching anything.
SELECT id, first_name, last_name, email_address, date_last_modified, last_maintained_by
FROM contacts
WHERE id = 1049;

-- 2) The update itself. Review the baseline above before running this --
--    confirm id=1049 and email_address='kisken@alltileccs.com' first.
BEGIN TRANSACTION;

UPDATE contacts
SET email_address = 'kevini@allsurfaces.com'
WHERE id = 1049
  AND email_address = 'kisken@alltileccs.com';  -- guards against re-running on an already-fixed or unexpectedly-changed row

SELECT @@ROWCOUNT AS rows_updated;  -- should be exactly 1 -- if 0, nothing matched (check baseline above); if >1, STOP and investigate before committing

-- 3) Verify before committing.
SELECT id, first_name, last_name, email_address, date_last_modified, last_maintained_by
FROM contacts
WHERE id = 1049;

-- 4) Only after confirming rows_updated = 1 and the verify SELECT looks right:
-- COMMIT TRANSACTION;

-- If anything looks wrong, instead run:
-- ROLLBACK TRANSACTION;
