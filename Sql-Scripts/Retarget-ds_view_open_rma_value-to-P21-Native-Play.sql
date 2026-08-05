use P21Play;

-- Legacy/non-P21 view cleanup (Deploy-Guides\ds_view_open_rma_value-retirement.md), not SA-51376.
-- Deploys the change already validated in P21Training to Play.
-- Repoints fc_dataobject_table 80 from ds_view_open_rma_value to a derived table over the
-- native p21_view_open_rma_report, and renames fc_dataobject_column 222 to match. Run
-- Remove-ds_view_open_rma_value-Column-Play.sql first.

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
