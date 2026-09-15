-- SA-53301 (follow-up to SA-51376): append a dated changelog line to custom_objects.version_desc
-- for the two P21Play role versions where the RMA tab column header was renamed from
-- "Lost Sales Desc" to "Reason" (2026-08-22), matching the established convention
-- (e.g. "-added carrier, class 1 | 20260805 - SA 51376 Add RMA Reason Code").

use P21Play;

DECLARE @uids TABLE (custom_objects_uid int PRIMARY KEY);
INSERT INTO @uids (custom_objects_uid) VALUES (158), (923);

-- === BEFORE ===
SELECT custom_objects_uid, version_id, version_desc
FROM custom_objects
WHERE custom_objects_uid IN (SELECT custom_objects_uid FROM @uids)
ORDER BY version_id;

-- === UPDATE ===
UPDATE custom_objects
SET version_desc = version_desc + ' | 20260822 - SA 53301 Rename RMA Reason Code column to Reason'
WHERE custom_objects_uid IN (SELECT custom_objects_uid FROM @uids);

-- === AFTER ===
SELECT custom_objects_uid, version_id, version_desc
FROM custom_objects
WHERE custom_objects_uid IN (SELECT custom_objects_uid FROM @uids)
ORDER BY version_id;
