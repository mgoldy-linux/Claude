-- SA 54806: Item Maintenance > Location List > "Select Additional Locations" popup
-- has no sort option on Company Name / Location Name (only Company ID / Location ID
-- render as sortable). This dialog is a P21 "popup" object (popup_detail /
-- popup_statement / popup_column), NOT a DynaChange window and NOT business-rule
-- editable. popup_statement.override_order_by is the sort override.

-- 1. Find the popup_detail_uid for this dialog
SELECT popup_detail_uid, popup_desc, created_by, date_created, date_last_modified
FROM popup_detail
WHERE popup_desc LIKE '%ocation%'
ORDER BY date_last_modified DESC;

-- 2. Once you have the uid(s) from step 1, check the current statement/order-by
--    (swap <uid> for the value found above)
SELECT popup_statement_uid, popup_detail_uid, from_join, order_by, override_where, override_order_by
FROM popup_statement
WHERE popup_detail_uid = <uid>;

-- 3. Columns exposed on the grid (confirm Company Name / Location Name are present
--    and see if there's a sortable/orderable flag per column)
SELECT *
FROM popup_column
WHERE popup_detail_uid = <uid>;

-- 4. Cross-check against p21_view_popup_statement (the view p21_dynachange_info_web-era
--    research pulled override_where/override_order_by from) in case the base
--    popup_statement row differs from what's actually in effect
SELECT override_where, override_order_by, *
FROM p21_view_popup_statement
WHERE popup_detail_uid = <uid>;
