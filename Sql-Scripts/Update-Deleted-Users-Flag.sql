-- Deleted user cleanup: flag P21 application users whose name carries the "** LEFT ... **" (or similar) marker
-- as delete_flag = 'Y'. Verified pattern (2026-08-25): 479 rows currently match name LIKE '%**%',
-- 463 already delete_flag='Y'; 16 are active='N' but still delete_flag='N' -- this script closes that gap.
-- Scope: dbo.users.delete_flag only. Does NOT touch active flag or drop the row -- soft-delete flag only.
use P21BusinessRules;

-- Preview: rows that will change (expect 16 as of 2026-08-25 -- re-run to confirm current count)
SELECT id, name, active, delete_flag
FROM dbo.users
WHERE name LIKE '%**%'
  AND ISNULL(delete_flag, 'N') <> 'Y'
ORDER BY name;

UPDATE dbo.users
SET delete_flag        = 'Y',
    date_last_modified = GETDATE(),
    last_maintained_by  = 'mgoldyn'
WHERE name LIKE '%**%'
  AND ISNULL(delete_flag, 'N') <> 'Y';

-- Verify after: should return 0 rows
SELECT id, name, active, delete_flag
FROM dbo.users
WHERE name LIKE '%**%'
  AND ISNULL(delete_flag, 'N') <> 'Y';
