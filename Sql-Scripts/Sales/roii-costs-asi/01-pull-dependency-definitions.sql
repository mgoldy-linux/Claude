/*
=====================================================================================================
 01 - Pull everything asi_sales_history_report_view_roii_costs still needs to know (read-only)
 Run in SSMS against Play first (P21Dev.allsurfaces.com / P21Play); later against Prod (P21) to confirm
 Prod's kb_ definitions match before any Prod deploy. Click each XML cell for the full, untruncated text.
 Paste results back into the session for phase 2 (js_ / direct-invoice replacement).
=====================================================================================================
*/
SET NOCOUNT ON;

-- 1. SQL version + compat level: decides whether the kb_ scalar UDFs were already being inlined
--    (SQL 2019+ at compat >= 150 can inline some scalar UDFs -- then the TVF gain is smaller; measure)
SELECT @@VERSION AS sql_version,
       d.name AS db, d.compatibility_level,
       (SELECT value FROM sys.database_scoped_configurations WHERE name = 'TSQL_SCALAR_UDF_INLINING') AS udf_inlining_on
FROM sys.databases d WHERE d.name = DB_NAME();
-- Prod 2026-10-02: SQL 2019 CU32 15.0.4435.7 Standard, compat 150, inlining on.
-- is_inlineable: kb_fn_get_sales_manager 0, kb_fn_get_sales_manager_names 0, kb_fn_get_product_manager 1, kb_fn_get_contact_name 1

IF COL_LENGTH('sys.sql_modules', 'is_inlineable') IS NOT NULL
	EXEC (N'SELECT OBJECT_NAME(m.object_id) AS fn, m.is_inlineable
	        FROM sys.sql_modules m
	        WHERE m.object_id IN (OBJECT_ID(''dbo.kb_fn_get_sales_manager''), OBJECT_ID(''dbo.kb_fn_get_sales_manager_names''),
	                              OBJECT_ID(''dbo.kb_fn_get_product_manager''), OBJECT_ID(''dbo.kb_fn_get_contact_name''))');

-- 2. Full definitions (processing-instruction XML = no SSMS grid truncation)
SELECT o.name, o.type_desc, o.modify_date,
       (SELECT [processing-instruction(def)] = OBJECT_DEFINITION(o.object_id) FOR XML PATH(''), TYPE) AS definition
FROM sys.objects o
WHERE o.name IN (
	'js_view_open_invoice_costs',            -- phase 2: what is it built on? static conversion table?
	'kb_view_direct_invoices_incl_rebills',  -- phase 2
	'kb_view_rebill_invoices',               -- phase 2 (under the direct view)
	'kb_view_oe_pick_ticket',                -- phase 2 (under the direct view)
	'kb_fn_get_sales_manager',               -- confirm Prod = Dev copy the TVF was written from
	'kb_fn_get_sales_manager_names',
	'kb_fn_get_product_manager',             -- kept as-is by the asi_ view (decision 2026-10-02)
	'kb_fn_get_contact_name',                -- confirm = asi_fn_get_contact_name (nickname '*' rule)
	'kb_sales_history_report_view_roii_costs' -- confirm Prod = the Play script this was built from
)
ORDER BY o.name;

-- 3. Who else reads the kb_ view (database side). SSRS side: see the ReportServer query at the bottom.
SELECT OBJECT_SCHEMA_NAME(d.referencing_id) + '.' + OBJECT_NAME(d.referencing_id) AS referencing_object,
       o.type_desc
FROM sys.sql_expression_dependencies d
JOIN sys.objects o ON o.object_id = d.referencing_id
WHERE d.referenced_id = OBJECT_ID('dbo.kb_sales_history_report_view_roii_costs');

-- 4. Indexes the OUTER APPLY rewrite leans on. If a key column below has no index whose FIRST
--    column it is, the matching APPLY becomes a scan per row -- check before trusting any timing.
--      invoice_line.invoice_line_uid_parent       (drv_sumlines, service orders only)
--      invoice_line.order_no + oe_line_number     (rewards inv_counter)
--      invoice_line.invoice_no                    (number_of_invoice_lines)
--      rewards_program_values.invoice_line_uid    (rewards)
--      invoice_hdr.invoice_date                   (the report's date filter drives everything)
SELECT OBJECT_NAME(i.object_id) AS tbl, i.name AS idx, i.type_desc, i.is_unique,
       STUFF((SELECT ', ' + c.name FROM sys.index_columns ic
              JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
              ORDER BY ic.key_ordinal FOR XML PATH('')), 1, 2, '') AS key_cols
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('dbo.invoice_line'), OBJECT_ID('dbo.invoice_hdr'),
                      OBJECT_ID('dbo.rewards_program_values'), OBJECT_ID('dbo.oe_line'))
  AND i.type > 0
ORDER BY tbl, idx;

-- 5. Uniqueness of the joins that were REMOVED as dead. If one of these is NOT unique on its join key,
--    the kb_ view was duplicating rows through it -> the EXCEPT/row counts in 02 will show it.
SELECT 'oe_line_dealer_commission per oe_line' AS chk, COUNT(*) AS keys_with_dupes
FROM (SELECT oe_line_uid FROM oe_line_dealer_commission GROUP BY oe_line_uid HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'progress_billing_x_invoice_hdr per (pb_uid, invoice)', COUNT(*)
FROM (SELECT oe_hdr_progress_billing_uid, invoice_no FROM progress_billing_x_invoice_hdr
      GROUP BY oe_hdr_progress_billing_uid, invoice_no HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'order_floor_plan_xref_10002 per oe_hdr', COUNT(*)
FROM (SELECT oe_hdr_uid FROM order_floor_plan_xref_10002 GROUP BY oe_hdr_uid HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'job_price_line per uid', COUNT(*)
FROM (SELECT job_price_line_uid FROM job_price_line GROUP BY job_price_line_uid HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'item_uom gallon per item (delete_flag N)', COUNT(*)
FROM (SELECT iu.inv_mast_uid FROM item_uom iu
      JOIN system_setting ss ON ss.configuration_id = 0 AND ss.name = 'Gallon_UOM' AND iu.unit_of_measure = ss.value
      WHERE iu.delete_flag = 'N' GROUP BY iu.inv_mast_uid HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'invoice_hdr with no address_history (INNER JOIN removed)', COUNT(*)
FROM invoice_hdr ih WITH (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM address_history ah WITH (NOLOCK) WHERE ah.address_history_uid = ih.sold_to_ah_uid);

/*
-- 6. SSRS: every report/dataset that names the kb_ view. Run on the report server's catalog DB
--    (ASDWDB01\ReportServer -- see reference_ssrs_report_server).
USE ReportServer;
SELECT c.Path, c.Name, c.Type, c.ModifiedDate
FROM dbo.Catalog c
WHERE c.Type IN (2, 8)    -- 2 = report, 8 = shared dataset
  AND CAST(CAST(c.Content AS VARBINARY(MAX)) AS VARCHAR(MAX)) LIKE '%kb_sales_history_report_view_roii_costs%'
ORDER BY c.Path;
*/

-- 7. Follow-up (added after the first Play run 2026-10-02)
-- 7a. Real table + indexes behind p21_view_rewards_program_values (section 4 found no 'rewards_program_values' table)
SELECT d.referenced_entity_name AS base_table
FROM sys.sql_expression_dependencies d
WHERE d.referencing_id = OBJECT_ID('dbo.p21_view_rewards_program_values');

-- 7b. oe_pick_ticket.invoice_no: data type + indexes (decides how the direct-ship check can seek)
SELECT c.name, TYPE_NAME(c.user_type_id) AS data_type, c.max_length, c.precision, c.scale
FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.oe_pick_ticket') AND c.name IN ('invoice_no', 'direct_shipment');

-- 7c. Indexes on the pick-ticket table and the rewards base table from 7a
SELECT OBJECT_NAME(i.object_id) AS tbl, i.name AS idx, i.type_desc,
       STUFF((SELECT ', ' + c.name FROM sys.index_columns ic
              JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
              ORDER BY ic.key_ordinal FOR XML PATH('')), 1, 2, '') AS key_cols
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('dbo.oe_pick_ticket'),
                      (SELECT TOP 1 d.referenced_id FROM sys.sql_expression_dependencies d
                       WHERE d.referencing_id = OBJECT_ID('dbo.p21_view_rewards_program_values')))
  AND i.type > 0
ORDER BY tbl, idx;

-- 7d. js_view_open_invoice_costs is a TABLE (not a view): its shape, size and what years it covers
SELECT c.name, TYPE_NAME(c.user_type_id) AS data_type, c.max_length
FROM sys.columns c WHERE c.object_id = OBJECT_ID('dbo.js_view_open_invoice_costs') ORDER BY c.column_id;

SELECT COUNT(*) AS rows_in_table, MIN(ih.invoice_date) AS first_invoice, MAX(ih.invoice_date) AS last_invoice
FROM js_view_open_invoice_costs j
LEFT JOIN invoice_hdr ih ON ih.invoice_no = j.invoice_no;

-- 7e. (fix for 7c, whose TOP 1 picked customer_x_rewards_program) -- the rewards view's definition and the
--     indexes on invoice_line_rewards. The rewards lookup in the asi_ view seeks by invoice_line_uid per line,
--     so an index whose FIRST key column reaches invoice_line_uid is needed.
SELECT (SELECT [processing-instruction(def)] = OBJECT_DEFINITION(OBJECT_ID('dbo.p21_view_rewards_program_values'))
        FOR XML PATH(''), TYPE) AS p21_view_rewards_program_values_def;

SELECT OBJECT_NAME(i.object_id) AS tbl, i.name AS idx, i.type_desc,
       STUFF((SELECT ', ' + c.name FROM sys.index_columns ic
              JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
              WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
              ORDER BY ic.key_ordinal FOR XML PATH('')), 1, 2, '') AS key_cols
FROM sys.indexes i
WHERE i.object_id IN (OBJECT_ID('dbo.invoice_line_rewards'), OBJECT_ID('dbo.rewards_program'))
  AND i.type > 0
ORDER BY tbl, idx;
