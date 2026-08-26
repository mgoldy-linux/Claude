-- SA-53301: finish step 3 (version_desc changelog) on Business Rules after the original
-- Prod script's note text overflowed varchar(255) on custom_objects_uid 2990 (Vendor
-- Maintenance role, 208-char existing version_desc). Steps 1 and 2 already succeeded and
-- committed on all 21 roles -- only version_desc is outstanding.
--
-- Shortened note + LEFT() safety net so no row can overflow the column again.

use P21BusinessRules;

-- === BEFORE ===
SELECT co.custom_objects_uid, LEN(co.version_desc) AS cur_len, co.version_desc
FROM custom_objects co
WHERE EXISTS (
    SELECT 1 FROM custom_objects_detail cod
    WHERE cod.custom_objects_uid = co.custom_objects_uid
      AND cod.object_name = 'ufc_lost_sales_lost_sales_desc_t'
      AND cod.attribute_name = 'create'
)
ORDER BY cur_len DESC;

-- === UPDATE ===
UPDATE co
SET co.version_desc = LEFT(co.version_desc + ' | 20260822 SA53301 renamed to Reason', 255),
    co.date_last_modified = GETDATE(),
    co.last_maintained_by = 'mgoldyn'
FROM custom_objects co
WHERE EXISTS (
    SELECT 1 FROM custom_objects_detail cod
    WHERE cod.custom_objects_uid = co.custom_objects_uid
      AND cod.object_name = 'ufc_lost_sales_lost_sales_desc_t'
      AND cod.attribute_name = 'create'
)
AND co.version_desc NOT LIKE '%SA53301 renamed to Reason%';

-- === AFTER ===
SELECT co.custom_objects_uid, LEN(co.version_desc) AS new_len, co.version_desc
FROM custom_objects co
WHERE EXISTS (
    SELECT 1 FROM custom_objects_detail cod
    WHERE cod.custom_objects_uid = co.custom_objects_uid
      AND cod.object_name = 'ufc_lost_sales_lost_sales_desc_t'
      AND cod.attribute_name = 'create'
)
ORDER BY new_len DESC;
