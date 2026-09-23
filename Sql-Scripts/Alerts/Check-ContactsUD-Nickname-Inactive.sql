-- Herm Claussen (contact 1061) is marked inactive via contacts_ud.nickname --
-- checking the actual schema/value before building logic on it, per house rule
-- (don't assume what the field holds or how "inactive" is spelled/stored).

-- 1) Full contacts_ud schema -- is nickname really where this lives, any other
--    similarly-repurposed columns worth knowing about?
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'contacts_ud'
ORDER BY ORDINAL_POSITION;

-- 2) Herm's actual row -- what does "inactive" actually look like in this field?
SELECT * FROM contacts_ud WHERE id = 1061;

-- 3) How many OTHER contacts use this same convention (so the audit query can
--    reliably detect it, not just special-case 1061)?
SELECT id, nickname
FROM contacts_ud
WHERE nickname IS NOT NULL
ORDER BY nickname;
