-- SA-53301: sync date_last_modified/last_maintained_by on the rows edited today (2026-08-22)
-- via direct SQL rather than the P21 client, so the audit trail isn't left stamped from the
-- original SA-51376 build. Matches existing convention (last_maintained_by = short login name).

use P21Play;

-- === BEFORE ===
SELECT custom_objects_detail_uid, date_last_modified, last_maintained_by
FROM custom_objects_detail
WHERE custom_objects_detail_uid IN (319335, 319349);

SELECT fc_dataobject_column_uid, date_last_modified, last_maintained_by
FROM fc_dataobject_column
WHERE fc_dataobject_column_uid = 461;

SELECT custom_objects_uid, date_last_modified, last_maintained_by
FROM custom_objects
WHERE custom_objects_uid IN (158, 923);

-- === UPDATE ===
UPDATE custom_objects_detail
SET date_last_modified = GETDATE(), last_maintained_by = 'mgoldyn'
WHERE custom_objects_detail_uid IN (319335, 319349);

UPDATE fc_dataobject_column
SET date_last_modified = GETDATE(), last_maintained_by = 'mgoldyn'
WHERE fc_dataobject_column_uid = 461;

UPDATE custom_objects
SET date_last_modified = GETDATE(), last_maintained_by = 'mgoldyn'
WHERE custom_objects_uid IN (158, 923);

-- === AFTER ===
SELECT custom_objects_detail_uid, date_last_modified, last_maintained_by
FROM custom_objects_detail
WHERE custom_objects_detail_uid IN (319335, 319349);

SELECT fc_dataobject_column_uid, date_last_modified, last_maintained_by
FROM fc_dataobject_column
WHERE fc_dataobject_column_uid = 461;

SELECT custom_objects_uid, date_last_modified, last_maintained_by
FROM custom_objects
WHERE custom_objects_uid IN (158, 923);
