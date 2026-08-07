use P21;

-- SA-51376: two of the 21 Prod role builds (system admin=913, product manager=917) left the
-- lost_sales_uid join-key column visible (width=500) instead of hidden (width=-1), the standard
-- trick for "need a join-key column present but not shown" on P21 Field Chooser fields.
-- Other 19 roles already have width=-1 for this column.

-- === BEFORE ===
SELECT custom_objects_uid, custom_objects_detail_uid, object_name, attribute_name, attribute_value
FROM custom_objects_detail
WHERE custom_objects_uid IN (913, 917)
  AND object_name = 'ufc_lost_sales_transaction_lost_sales_uid'
  AND attribute_name = 'width';

-- === UPDATE ===
UPDATE custom_objects_detail
SET attribute_value = '-1'
WHERE custom_objects_uid IN (913, 917)
  AND object_name = 'ufc_lost_sales_transaction_lost_sales_uid'
  AND attribute_name = 'width';

-- === AFTER ===
SELECT custom_objects_uid, custom_objects_detail_uid, object_name, attribute_name, attribute_value
FROM custom_objects_detail
WHERE custom_objects_uid IN (913, 917)
  AND object_name = 'ufc_lost_sales_transaction_lost_sales_uid'
  AND attribute_name = 'width';
