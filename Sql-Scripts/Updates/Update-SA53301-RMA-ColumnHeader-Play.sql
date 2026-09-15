-- SA-53301 (follow-up to SA-51376): rename the RMA tab column header on Transaction Master
-- Inquiry Orders from "Lost Sales Desc" to "Reason". Field = ufc_lost_sales_lost_sales_desc
-- (fc_dataobject_column_uid 461), built for SA-51376.
--
-- The header is NOT a separate override attribute row -- it's embedded inside the serialized
-- PowerBuilder "create text(...)" blob for the paired "_t" text object
-- (ufc_lost_sales_lost_sales_desc_t), one row per DynaChange role version. No standalone
-- 'text' attribute_name row exists for this field in Play (checked).
--
-- In P21Play, this field is only placed on 2 of the 21 role versions (per SA-51376 deploy
-- guide testing notes):
--   - screen_transaction_master_inquiry_orders_all                    (custom_objects_uid 158)
--   - screen_transaction_master_inquiry_orders_customer service manager (custom_objects_uid 923)
--
-- Also updating fc_dataobject_column.description (the layer-1 shared field definition) so any
-- future placement via Field Chooser defaults to "Reason" instead of "Lost Sales Desc".

use P21Play;

-- === BEFORE ===
SELECT custom_objects_detail_uid, attribute_value
FROM custom_objects_detail
WHERE custom_objects_detail_uid IN (319335, 319349);

SELECT fc_dataobject_column_uid, user_column_name, description
FROM fc_dataobject_column
WHERE fc_dataobject_column_uid = 461;

-- === UPDATE ===
UPDATE custom_objects_detail
SET attribute_value = REPLACE(attribute_value, 'text="Lost Sales Desc"', 'text="Reason"')
WHERE custom_objects_detail_uid IN (319335, 319349)
  AND object_name = 'ufc_lost_sales_lost_sales_desc_t'
  AND attribute_name = 'create';

UPDATE fc_dataobject_column
SET description = 'Reason'
WHERE fc_dataobject_column_uid = 461
  AND user_column_name = 'ufc_lost_sales_lost_sales_desc';

-- === AFTER ===
SELECT custom_objects_detail_uid, attribute_value
FROM custom_objects_detail
WHERE custom_objects_detail_uid IN (319335, 319349);

SELECT fc_dataobject_column_uid, user_column_name, description
FROM fc_dataobject_column
WHERE fc_dataobject_column_uid = 461;

-- Rollback if needed:
-- UPDATE custom_objects_detail SET attribute_value = REPLACE(attribute_value, 'text="Reason"', 'text="Lost Sales Desc"') WHERE custom_objects_detail_uid IN (319335, 319349);
-- UPDATE fc_dataobject_column SET description = 'Lost Sales Desc' WHERE fc_dataobject_column_uid = 461;
