/*
=====================================================================================================
 03 - Prove dbo.asi_fnt_invoice_detail(@d_start, @d_end) returns exactly what the Invoice Detail report
      gets today from kb_sales_history_report_view_roii_costs, then compare cost (logical reads / CPU).
 Run in SSMS on P21Play after creating, in order:
      SQL-Schema\CREATE-OR-ALTER-FUNCTION-asi_fnt_get_sales_manager.sql
      SQL-Schema\CREATE-OR-ALTER-VIEW-asi_view_rebill_invoices.sql
      SQL-Schema\CREATE-TABLE-asi_table_dancik_open_invoice_costs.sql
      SQL-Schema\CREATE-OR-ALTER-FUNCTION-asi_fnt_invoice_detail.sql
 Read-only. Start with a 1-month window; then year-to-date, the size aboeve runs (~165K rows).
=====================================================================================================
*/
SET NOCOUNT ON;
DECLARE @d_start DATETIME = '2026-08-01', @d_end DATETIME = '2026-08-31 23:59:59';

-------------------------------------------------------------------------------
-- A. Same rows, same values, for the 45 columns the report reads
-------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#kb')  IS NOT NULL DROP TABLE #kb;
IF OBJECT_ID('tempdb..#asi') IS NOT NULL DROP TABLE #asi;

SELECT invoice_date,
       invoice_no,
       order_no,
       customer_id,
       customer_name,
       chain,
       po_no,
       sales_location_id,
       direct_flag,
       order_date,
       taker,
       job_name,
       qty_shipped,
       item_id,
       line_no,
       oe_line_number,
       pricing_unit,
       invoice_line_uid,
       product_group_desc,
       incentive_rewards,
       coop_rewards,
       rebate_flag,
       unit_price,
       sales_price_home,
       line_other_cost_home,
       gross_profit_dollars,
       pricing_unit_size,
       manual_price_overide,
       oe_line_rewards_flag,
       cost_price_page_uid,
       pricing_method,
       source_location_name,
       sales_location_name,
       ship_location_name,
       item_class1,
       item_class2,
       extended_desc,
       base_unit,
       price_family_id,
       price_family_desc,
       salesrep_id,
       salesrep_name,
       manager_id,
       manager_name,
       product_manager_id
INTO #kb
FROM dbo.kb_sales_history_report_view_roii_costs
WHERE invoice_date BETWEEN @d_start AND @d_end;

SELECT invoice_date,
       invoice_no,
       order_no,
       customer_id,
       customer_name,
       chain,
       po_no,
       sales_location_id,
       direct_flag,
       order_date,
       taker,
       job_name,
       qty_shipped,
       item_id,
       line_no,
       oe_line_number,
       pricing_unit,
       invoice_line_uid,
       product_group_desc,
       incentive_rewards,
       coop_rewards,
       rebate_flag,
       unit_price,
       sales_price_home,
       line_other_cost_home,
       gross_profit_dollars,
       pricing_unit_size,
       manual_price_overide,
       oe_line_rewards_flag,
       cost_price_page_uid,
       pricing_method,
       source_location_name,
       sales_location_name,
       ship_location_name,
       item_class1,
       item_class2,
       extended_desc,
       base_unit,
       price_family_id,
       price_family_desc,
       salesrep_id,
       salesrep_name,
       manager_id,
       manager_name,
       product_manager_id
INTO #asi
FROM dbo.asi_fnt_invoice_detail(@d_start, @d_end);

SELECT (SELECT COUNT(*) FROM #kb)  AS kb_rows,
       (SELECT COUNT(*) FROM #asi) AS asi_rows,
       (SELECT COUNT(*) FROM (SELECT * FROM #kb  EXCEPT SELECT * FROM #asi) x) AS in_kb_not_asi,
       (SELECT COUNT(*) FROM (SELECT * FROM #asi EXCEPT SELECT * FROM #kb)  y) AS in_asi_not_kb;
-- expected: kb_rows = asi_rows, 0 / 0

-- B. Duplicate lines. The kb_ view joins ~20 tables the report never reads; if any of them returned
--    2+ rows per invoice line, the report has been showing that line more than once. asi_ should show none.
SELECT 'kb_' AS src, COUNT(*) AS lines_duplicated
FROM (SELECT invoice_line_uid FROM #kb GROUP BY invoice_line_uid HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'asi_', COUNT(*)
FROM (SELECT invoice_line_uid FROM #asi GROUP BY invoice_line_uid HAVING COUNT(*) > 1) d;
-- if kb_ > 0 and asi_ = 0, A's row counts differ by exactly those extra copies -- a fix, not a regression

-- If A is not 0/0 and duplicates don't explain it: which columns differ
/*
SELECT col, COUNT(*) AS lines_differing
FROM #kb k JOIN #asi a ON a.invoice_line_uid = k.invoice_line_uid
CROSS APPLY (VALUES
	('sales_price_home',     CASE WHEN EXISTS (SELECT k.sales_price_home     EXCEPT SELECT a.sales_price_home)     THEN 1 END),
	('line_other_cost_home', CASE WHEN EXISTS (SELECT k.line_other_cost_home EXCEPT SELECT a.line_other_cost_home) THEN 1 END),
	('gross_profit_dollars', CASE WHEN EXISTS (SELECT k.gross_profit_dollars EXCEPT SELECT a.gross_profit_dollars) THEN 1 END),
	('unit_price',           CASE WHEN EXISTS (SELECT k.unit_price           EXCEPT SELECT a.unit_price)           THEN 1 END),
	('incentive_rewards',    CASE WHEN EXISTS (SELECT k.incentive_rewards    EXCEPT SELECT a.incentive_rewards)    THEN 1 END),
	('coop_rewards',         CASE WHEN EXISTS (SELECT k.coop_rewards         EXCEPT SELECT a.coop_rewards)         THEN 1 END),
	('manager_id',           CASE WHEN EXISTS (SELECT k.manager_id           EXCEPT SELECT a.manager_id)           THEN 1 END),
	('manager_name',         CASE WHEN EXISTS (SELECT k.manager_name         EXCEPT SELECT a.manager_name)         THEN 1 END),
	('direct_flag',          CASE WHEN EXISTS (SELECT k.direct_flag          EXCEPT SELECT a.direct_flag)          THEN 1 END),
	('rebate_flag',          CASE WHEN EXISTS (SELECT k.rebate_flag          EXCEPT SELECT a.rebate_flag)          THEN 1 END),
	('pricing_method',       CASE WHEN EXISTS (SELECT k.pricing_method       EXCEPT SELECT a.pricing_method)       THEN 1 END),
	('product_group_desc',   CASE WHEN EXISTS (SELECT k.product_group_desc   EXCEPT SELECT a.product_group_desc)   THEN 1 END)
) v(col, diff)
WHERE v.diff = 1
GROUP BY col;
*/

-------------------------------------------------------------------------------
-- C. The new building blocks on their own
-------------------------------------------------------------------------------
-- C1. sales manager TVF vs the two kb_ scalar functions, every salesrep x commission class
SELECT COUNT(*) AS sm_mismatches
FROM (SELECT c.id FROM contacts c WITH (NOLOCK) WHERE c.salesrep = 'Y') r
CROSS JOIN (SELECT commission_class_id FROM item_commission_class_ud UNION SELECT NULL) cc
OUTER APPLY dbo.asi_fnt_get_sales_manager(r.id, cc.commission_class_id) sm
WHERE EXISTS (
	SELECT dbo.kb_fn_get_sales_manager(r.id, cc.commission_class_id, NULL),
	       dbo.kb_fn_get_sales_manager_names(CONVERT(INT, r.id), cc.commission_class_id, NULL)
	EXCEPT
	SELECT sm.sales_manager_id, sm.sales_manager_names);
-- expected: 0

-- C2. rebill view port
SELECT (SELECT COUNT(*) FROM (SELECT * FROM dbo.kb_view_rebill_invoices EXCEPT SELECT * FROM dbo.asi_view_rebill_invoices) x) AS in_kb_not_asi,
       (SELECT COUNT(*) FROM (SELECT * FROM dbo.asi_view_rebill_invoices EXCEPT SELECT * FROM dbo.kb_view_rebill_invoices) y) AS in_asi_not_kb;
-- expected: 0 / 0

-- C3. Dancik cost table copy
SELECT (SELECT COUNT(*) FROM (SELECT * FROM dbo.js_view_open_invoice_costs EXCEPT SELECT * FROM dbo.asi_table_dancik_open_invoice_costs) x) AS in_js_not_asi,
       (SELECT COUNT(*) FROM (SELECT * FROM dbo.asi_table_dancik_open_invoice_costs EXCEPT SELECT * FROM dbo.js_view_open_invoice_costs) y) AS in_asi_not_js;
-- expected: 0 / 0

-------------------------------------------------------------------------------
-- D. Cost, in the report's own shape. Run D1 and D2 2-3 times each, then D3.
--    Second pass: set the dates to year-to-date and @pm = 'ABOEVE' (aboeve's real use).
-------------------------------------------------------------------------------
DECLARE @pm VARCHAR(50) = NULL;

-- D1
SELECT /* invdet_perf_KB */ COUNT(*), SUM(shrv.sales_price_home), MAX(shrv.manager_name)
FROM dbo.kb_sales_history_report_view_roii_costs AS shrv
WHERE shrv.invoice_date BETWEEN @d_start AND @d_end
  AND (@pm IS NULL OR shrv.product_manager_id = @pm);

-- D2
SELECT /* invdet_perf_ASI */ COUNT(*), SUM(shrv.sales_price_home), MAX(shrv.manager_name)
FROM dbo.asi_fnt_invoice_detail(@d_start, @d_end) AS shrv
WHERE (@pm IS NULL OR shrv.product_manager_id = @pm);

-- D3. The numbers to quote: logical reads and CPU, not elapsed time
SELECT CASE WHEN t.text LIKE '%invdet_perf_KB%' THEN 'kb_' ELSE 'asi_' END AS version,
       qs.execution_count,
       qs.total_worker_time   / qs.execution_count / 1000 AS avg_cpu_ms,
       qs.total_logical_reads / qs.execution_count        AS avg_logical_reads,
       qs.last_dop,
       qs.total_elapsed_time  / qs.execution_count / 1000 AS avg_elapsed_ms_IGNORE_ON_PROD
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
WHERE (t.text LIKE '%invdet_perf_KB%' OR t.text LIKE '%invdet_perf_ASI%')
  AND t.text NOT LIKE '%dm_exec_query_stats%';

-- the kb_ side's scalar functions are billed separately -- add these to its row above
SELECT OBJECT_NAME(fs.object_id) AS scalar_udf, fs.execution_count,
       fs.total_worker_time / 1000 AS total_cpu_ms, fs.total_logical_reads
FROM sys.dm_exec_function_stats fs
WHERE fs.database_id = DB_ID()
  AND fs.object_id IN (OBJECT_ID('dbo.kb_fn_get_sales_manager'), OBJECT_ID('dbo.kb_fn_get_sales_manager_names'),
                       OBJECT_ID('dbo.kb_fn_get_contact_name'));
