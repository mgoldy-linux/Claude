use P21Training;

-- Legacy/non-P21 view cleanup (Deploy-Guides\ds_view_open_rma_value-retirement.md), not SA-51376.
-- Repoints the Open Total Value field's source from the custom ds_view_open_rma_value
-- wrapper to the native P21 view (p21_view_open_rma_report) underneath it.
-- fc_dataobject_column row 222 still resolves fine against the new source (same
-- order_no/open_total_value columns), so the field does NOT need to be re-created via
-- "New Field" in Field Chooser -- it can be re-added to each of the 6 role versions from
-- the existing field list. Its internal user_column_name still says "ds_view_open_rma_value"
-- even after the retarget below; renamed here too so nothing keeps referencing the retired
-- view's name. description (the field's display label, "Open Total Value") is left as-is.

-- === BEFORE ===
SELECT fc_dataobject_table_uid, fc_dataobject_uid, table_name, join_syntax
FROM fc_dataobject_table
WHERE fc_dataobject_table_uid = 80;

SELECT fc_dataobject_column_uid, user_column_name, column_name, description, fc_dataobject_table_uid
FROM fc_dataobject_column
WHERE fc_dataobject_table_uid = 80;

-- === UPDATE: retarget the join ===
UPDATE dbo.fc_dataobject_table
SET table_name = 'p21_view_open_rma_report',
    join_syntax = 'LEFT JOIN (SELECT DISTINCT order_no, open_total_value FROM p21_view_open_rma_report) p21_view_open_rma_report on p21_view_open_rma_report.order_no = oe_hdr.order_no'
WHERE fc_dataobject_table_uid = 80;

-- === UPDATE: rename the field's internal name to match ===
UPDATE dbo.fc_dataobject_column
SET user_column_name = 'ufc_p21_view_open_rma_report_open_total_value'
WHERE fc_dataobject_column_uid = 222;

-- === AFTER ===
SELECT fc_dataobject_table_uid, fc_dataobject_uid, table_name, join_syntax
FROM fc_dataobject_table
WHERE fc_dataobject_table_uid = 80;

SELECT fc_dataobject_column_uid, user_column_name, column_name, description, fc_dataobject_table_uid, row_status_flag
FROM fc_dataobject_column
WHERE fc_dataobject_table_uid = 80;
