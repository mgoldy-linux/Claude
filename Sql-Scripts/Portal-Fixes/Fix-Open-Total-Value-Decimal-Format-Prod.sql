use P21;

-- Legacy/non-P21 view cleanup (ds_view_open_rma_value retirement), not SA-51376.
-- The re-added Open Total Value field inherited a 9-decimal mask
-- (editmask.mask="##,###,###,###,###.000000000") instead of the standard 2-decimal
-- currency mask used elsewhere in P21 (e.g. ufc_opportunity_ud_labor_amount:
-- editmask.mask="##,###,###,###,###.00"). Fixes it across all 6 role versions the field
-- was re-added to. WHERE clause only matches rows still on the old mask, so it's safe to
-- re-run.

-- === BEFORE ===
SELECT co.custom_objects_uid, co.version_id, cod.custom_objects_detail_uid, cod.attribute_value
FROM custom_objects co
JOIN custom_objects_detail cod ON cod.custom_objects_uid = co.custom_objects_uid
WHERE cod.object_name = 'ufc_p21_view_open_rma_report_open_total_value'
  AND cod.attribute_name = 'create'
  AND co.custom_objects_uid IN (158, 922, 923, 929, 930, 2990);

-- === UPDATE ===
UPDATE custom_objects_detail
SET attribute_value = REPLACE(attribute_value, 'editmask.mask="##,###,###,###,###.000000000"', 'editmask.mask="##,###,###,###,###.00"')
WHERE object_name = 'ufc_p21_view_open_rma_report_open_total_value'
  AND attribute_name = 'create'
  AND custom_objects_uid IN (158, 922, 923, 929, 930, 2990)
  AND attribute_value LIKE '%editmask.mask="##,###,###,###,###.000000000"%';

-- === AFTER ===
SELECT co.custom_objects_uid, co.version_id, cod.custom_objects_detail_uid, cod.attribute_value
FROM custom_objects co
JOIN custom_objects_detail cod ON cod.custom_objects_uid = co.custom_objects_uid
WHERE cod.object_name = 'ufc_p21_view_open_rma_report_open_total_value'
  AND cod.attribute_name = 'create'
  AND co.custom_objects_uid IN (158, 922, 923, 929, 930, 2990);
