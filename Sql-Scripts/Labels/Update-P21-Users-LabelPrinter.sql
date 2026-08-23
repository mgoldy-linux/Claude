-- Update-P21-Users-LabelPrinter.sql
-- Sets default_label_printer = 'print.allsurfaces.com' for THALL and MREDMOND.
-- Run against: P21 Prod
-- 2026-06-15

USE P21;
GO

-- Preview before update
SELECT id, name, default_label_printer
FROM users
WHERE id IN ('THALL', 'MREDMOND');

-- Update
UPDATE users
SET    default_label_printer = 'print.allsurfaces.com'
WHERE  id IN ('THALL', 'MREDMOND');

-- Confirm
SELECT id, name, default_label_printer
FROM users
WHERE id IN ('THALL', 'MREDMOND');
