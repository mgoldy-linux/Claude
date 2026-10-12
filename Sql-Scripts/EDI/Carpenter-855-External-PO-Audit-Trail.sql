-- Who/what changed po_hdr.external_po_no, and from what old value? Read-only, Prod (P21).
-- Compares Carpenter POs that did NOT take the 855 number vs Roppe/Schluter POs that did.
USE P21
GO

-- 0) Verify the raw column name + table columns first (audit_trail stores raw names, not captions)
SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'audit_trail' ORDER BY ORDINAL_POSITION;

SELECT TOP 20 column_changed, COUNT(*) AS n
FROM audit_trail
WHERE key1_value IN ('4327858','4327795','4327672','4327646','4327822')
GROUP BY column_changed ORDER BY n DESC;
GO

-- 1) Full external_po_no history for sample POs
--    Carpenter NOT updated: 4327858, 4327795, 4327672, 4327538, 4327212, 4326365 (3003676) + 4327012 (3003672)
--    Carpenter leading-zero:  4327646, 4327612
--    Carpenter updated by import: 4327856, 4327088
--    Roppe (updated by import): 4327822, 4327821 | Schluter: 4327787, 4327784
SELECT key1_value AS po_no, date_created, created_by, column_changed, old_value, new_value
FROM audit_trail
WHERE key1_value IN ('4327858','4327795','4327672','4327538','4327212','4326365','4327012',
                     '4327646','4327612','4327856','4327088',
                     '4327822','4327821','4327787','4327784')
  AND column_changed LIKE '%external_po%'
ORDER BY key1_value, date_created;
GO
