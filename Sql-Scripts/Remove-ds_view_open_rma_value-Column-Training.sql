use P21Training;

-- SA: none (legacy/non-P21 view cleanup, tracked in Deploy-Guides\ds_view_open_rma_value-retirement.md)
-- Removes the ufc_ds_view_open_rma_value_open_total_value column from the 6 role-based
-- Transaction Master Inquiry Orders versions that currently place it, ahead of retiring
-- the ds_view_open_rma_value view itself.

-- === BEFORE: confirm what's about to be deleted ===
SELECT co.custom_objects_uid, co.version_id, cod.custom_objects_detail_uid, cod.object_name, cod.attribute_name, cod.attribute_value
FROM custom_objects co
JOIN custom_objects_detail cod ON cod.custom_objects_uid = co.custom_objects_uid
WHERE co.custom_objects_uid IN (158, 922, 923, 929, 930, 2990)
  AND cod.object_name IN ('ufc_ds_view_open_rma_value_open_total_value','ufc_ds_view_open_rma_value_open_total_value_t')
ORDER BY co.custom_objects_uid, cod.object_name, cod.attribute_name;

-- === DELETE ===
DELETE FROM custom_objects_detail
WHERE custom_objects_uid IN (158, 922, 923, 929, 930, 2990)
  AND object_name IN ('ufc_ds_view_open_rma_value_open_total_value','ufc_ds_view_open_rma_value_open_total_value_t');

-- === AFTER: should return 0 rows ===
SELECT co.custom_objects_uid, co.version_id, cod.custom_objects_detail_uid, cod.object_name, cod.attribute_name
FROM custom_objects co
JOIN custom_objects_detail cod ON cod.custom_objects_uid = co.custom_objects_uid
WHERE co.custom_objects_uid IN (158, 922, 923, 929, 930, 2990)
  AND cod.object_name IN ('ufc_ds_view_open_rma_value_open_total_value','ufc_ds_view_open_rma_value_open_total_value_t');

-- Optional: log the removal in each affected version's changelog, matching the existing comment convention
-- (uncomment and run per uid, or adapt into a loop)
 UPDATE custom_objects SET version_desc = version_desc + ' | 20260805 - removed open_total_value column ahead of ds_view_open_rma_value retirement' WHERE custom_objects_uid = 158;
 UPDATE custom_objects SET version_desc = version_desc + ' | 20260805 - removed open_total_value column ahead of ds_view_open_rma_value retirement' WHERE custom_objects_uid = 922;
 UPDATE custom_objects SET version_desc = version_desc + ' | 20260805 - removed open_total_value column ahead of ds_view_open_rma_value retirement' WHERE custom_objects_uid = 923;
 UPDATE custom_objects SET version_desc = version_desc + ' | 20260805 - removed open_total_value column ahead of ds_view_open_rma_value retirement' WHERE custom_objects_uid = 929;
 UPDATE custom_objects SET version_desc = version_desc + ' | 20260805 - removed open_total_value column ahead of ds_view_open_rma_value retirement' WHERE custom_objects_uid = 930;
 UPDATE custom_objects SET version_desc = version_desc + ' | 20260805 - removed open_total_value column ahead of ds_view_open_rma_value retirement' WHERE custom_objects_uid = 2990;
