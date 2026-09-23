-- Does deleting a contact (salesrep) actually remove/blank the fields the alert
-- engine reads, or just flip a status column? Checking before assuming, per house rule.

-- 1) Does contacts have its own delete/status column (separate from users.delete_flag)?
SELECT TABLE_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'contacts'
  AND (COLUMN_NAME LIKE '%delete%' OR COLUMN_NAME LIKE '%status%' OR COLUMN_NAME LIKE '%active%');

-- 2) Contact 1045's current full row -- baseline before any delete action, so a
--    before/after diff is possible if you do test the delete in a non-Prod env.
SELECT * FROM contacts WHERE id = 1045;
