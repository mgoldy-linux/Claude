-- Set default_label_printer for active P21BusinessRules users missing one.
-- Scope: dbo.users where delete_flag = 'N' and default_label_printer IS NULL.
-- Sets default_label_printer = 'print.allsurfaces.com'.
use P21BusinessRules;

-- Preview: rows that will change
SELECT id, name, delete_flag, default_label_printer
FROM dbo.users
WHERE delete_flag = 'N'
  AND default_label_printer IS NULL
ORDER BY name;

UPDATE dbo.users
SET default_label_printer = 'print.allsurfaces.com',
    date_last_modified    = GETDATE(),
    last_maintained_by    = 'mgoldyn'
WHERE delete_flag = 'N'
  AND default_label_printer IS NULL;

-- Verify after: should return 0 rows
SELECT id, name, delete_flag, default_label_printer
FROM dbo.users
WHERE delete_flag = 'N'
  AND default_label_printer IS NULL;
