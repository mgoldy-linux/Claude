use P21Play;

-- Legacy/non-P21 view cleanup (Deploy-Guides\ds_view_open_rma_value-retirement.md), not SA-51376.
-- Deploys the change already validated in P21Training to Play.
-- Removes the ufc_ds_view_open_rma_value_open_total_value column from the 6 role-based
-- Transaction Master Inquiry Orders versions that currently place it, ahead of retargeting
-- fc_dataobject_table 80 to the native p21_view_open_rma_report.

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
