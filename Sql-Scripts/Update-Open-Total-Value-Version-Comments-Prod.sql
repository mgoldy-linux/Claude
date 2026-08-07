use P21;

-- Legacy/non-P21 view cleanup (ds_view_open_rma_value retirement), not SA-51376.
-- Logs the re-add + fixes to each of the 6 role versions' changelog, matching the existing
-- dated pipe-delimited comment convention (e.g. "-added carrier, class 1 | 20260805 - ...").

-- === BEFORE ===
SELECT custom_objects_uid, version_id, version_desc
FROM custom_objects
WHERE custom_objects_uid IN (158, 922, 923, 929, 930, 2990);

-- === UPDATE ===
UPDATE custom_objects
SET version_desc = version_desc + ' | 20260806 - restored open_total_value sourced from p21_view_open_rma_report (native), 2-decimal format fixed'
WHERE custom_objects_uid IN (158, 922, 923, 929, 930, 2990);

-- === AFTER ===
SELECT custom_objects_uid, version_id, version_desc
FROM custom_objects
WHERE custom_objects_uid IN (158, 922, 923, 929, 930, 2990);
