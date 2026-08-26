-- SA-53301 (follow-up to SA-51376): rename the RMA tab column header on Transaction Master
-- Inquiry Orders from "Lost Sales Desc" to "Reason" -- PROD.
--
-- Same fix as Play (Update-SA53301-RMA-ColumnHeader-Play.sql / Update-SA53301-Version-Desc-Play.sql
-- / Update-SA53301-AuditColumns-Play.sql), but set-based instead of a hardcoded uid list, since
-- Prod has all 21 role versions of this screen carrying the field (confirmed 2026-08-22 -- SA-51376
-- was rolled out to all 21 roles in Prod, vs. only 2 tested in Play).
--
-- Scoped by object_name/attribute_name/user_column_name rather than specific uids, so this covers
-- however many roles actually have the field placed -- no need to enumerate them by hand.

use P21;

-- === BEFORE ===
SELECT co.version_id, co.custom_objects_uid, cod.custom_objects_detail_uid, cod.attribute_value,
       co.version_desc, co.date_last_modified AS co_date_last_modified, co.last_maintained_by AS co_last_maintained_by
FROM custom_objects_detail cod
JOIN custom_objects co ON co.custom_objects_uid = cod.custom_objects_uid
WHERE cod.object_name = 'ufc_lost_sales_lost_sales_desc_t'
  AND cod.attribute_name = 'create'
ORDER BY co.version_id;

SELECT fc_dataobject_column_uid, user_column_name, description, date_last_modified, last_maintained_by
FROM fc_dataobject_column
WHERE user_column_name = 'ufc_lost_sales_lost_sales_desc';

-- === UPDATE ===

-- 1. Header text object (per role version) -- set-based, matches however many roles have it placed
UPDATE custom_objects_detail
SET attribute_value = REPLACE(attribute_value, 'text="Lost Sales Desc"', 'text="Reason"'),
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE object_name = 'ufc_lost_sales_lost_sales_desc_t'
  AND attribute_name = 'create'
  AND attribute_value LIKE '%text="Lost Sales Desc"%';

-- 2. Shared field definition (single row, layer 1 -- default label for future placements)
UPDATE fc_dataobject_column
SET description = 'Reason',
    date_last_modified = GETDATE(),
    last_maintained_by = 'mgoldyn'
WHERE user_column_name = 'ufc_lost_sales_lost_sales_desc'
  AND description = 'Lost Sales Desc';

-- 3. version_desc changelog -- only on the role versions that actually have the field placed.
--    version_desc is varchar(255); the "Vendor Maintenance" role (uid 2990 in Business Rules,
--    same role exists in Prod) already carries a 208-char description, so the note is kept
--    short and wrapped in LEFT() as a safety net against any row overflowing the column
--    (confirmed 2026-08-25 -- the original longer note truncated with error 2628 on this
--    exact role when tested against Business Rules, refreshed from Prod that same day).
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
SELECT co.version_id, co.custom_objects_uid, cod.custom_objects_detail_uid, cod.attribute_value,
       co.version_desc, co.date_last_modified AS co_date_last_modified, co.last_maintained_by AS co_last_maintained_by
FROM custom_objects_detail cod
JOIN custom_objects co ON co.custom_objects_uid = cod.custom_objects_uid
WHERE cod.object_name = 'ufc_lost_sales_lost_sales_desc_t'
  AND cod.attribute_name = 'create'
ORDER BY co.version_id;

SELECT fc_dataobject_column_uid, user_column_name, description, date_last_modified, last_maintained_by
FROM fc_dataobject_column
WHERE user_column_name = 'ufc_lost_sales_lost_sales_desc';

-- Rollback if needed:
-- UPDATE custom_objects_detail SET attribute_value = REPLACE(attribute_value, 'text="Reason"', 'text="Lost Sales Desc"') WHERE object_name = 'ufc_lost_sales_lost_sales_desc_t' AND attribute_name = 'create' AND attribute_value LIKE '%text="Reason"%';
-- UPDATE fc_dataobject_column SET description = 'Lost Sales Desc' WHERE user_column_name = 'ufc_lost_sales_lost_sales_desc' AND description = 'Reason';
-- (version_desc / audit column rollback would need to strip the appended note manually -- not scripted, low risk to leave as-is)
