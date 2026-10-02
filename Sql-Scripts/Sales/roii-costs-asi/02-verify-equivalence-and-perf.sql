/*
=====================================================================================================
 02 - Prove asi_sales_history_report_view_roii_costs == kb_sales_history_report_view_roii_costs,
      then measure both from the plan cache (logical reads / CPU -- NOT wall-clock).
 Run in SSMS on P21Play after deploying (in order):
      SQL-Schema\CREATE-OR-ALTER-FUNCTION-asi_fnt_get_sales_manager.sql
      SQL-Schema\CREATE-OR-ALTER-VIEW-asi_view_rebill_invoices.sql
      SQL-Schema\CREATE-TABLE-asi_table_dancik_open_invoice_costs.sql
      SQL-Schema\CREATE-OR-ALTER-VIEW-asi_sales_history_report_view_roii_costs.sql
 Read-only. Start with a 1-month window; widen to a year once that passes.
=====================================================================================================
*/
SET NOCOUNT ON;
DECLARE @d_start DATETIME = '2026-08-01', @d_end DATETIME = '2026-08-31 23:59:59';

-------------------------------------------------------------------------------
-- A. Column contract: same names, same order, same types (SSRS binds by name, but keep it exact)
-------------------------------------------------------------------------------
SELECT COALESCE(k.column_id, a.column_id) AS column_id, k.name AS kb_col, a.name AS asi_col,
       TYPE_NAME(k.user_type_id) AS kb_type, TYPE_NAME(a.user_type_id) AS asi_type,
       k.max_length AS kb_len, a.max_length AS asi_len
FROM (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.kb_sales_history_report_view_roii_costs')) k
FULL JOIN (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.asi_sales_history_report_view_roii_costs')) a
	ON a.column_id = k.column_id
WHERE k.name IS NULL OR a.name IS NULL OR k.name <> a.name
   OR k.user_type_id <> a.user_type_id OR k.max_length <> a.max_length
   OR k.precision <> a.precision OR k.scale <> a.scale;
-- expected: 0 rows

-------------------------------------------------------------------------------
-- B. Row equivalence. EXCEPT is set-based (hides duplicates), so counts are compared too.
-------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#kb') IS NOT NULL DROP TABLE #kb;
IF OBJECT_ID('tempdb..#asi') IS NOT NULL DROP TABLE #asi;

SELECT * INTO #kb  FROM dbo.kb_sales_history_report_view_roii_costs  WHERE invoice_date BETWEEN @d_start AND @d_end;
SELECT * INTO #asi FROM dbo.asi_sales_history_report_view_roii_costs WHERE invoice_date BETWEEN @d_start AND @d_end;

SELECT (SELECT COUNT(*) FROM #kb) AS kb_rows,
       (SELECT COUNT(*) FROM #asi) AS asi_rows,
       (SELECT COUNT(DISTINCT invoice_line_uid) FROM #kb) AS kb_distinct_lines,
       (SELECT COUNT(DISTINCT invoice_line_uid) FROM #asi) AS asi_distinct_lines,
       (SELECT COUNT(*) FROM (SELECT * FROM #kb EXCEPT SELECT * FROM #asi) x) AS in_kb_not_asi,
       (SELECT COUNT(*) FROM (SELECT * FROM #asi EXCEPT SELECT * FROM #kb) y) AS in_asi_not_kb;
-- expected: kb_rows = asi_rows, distinct equal, 0 / 0

-- If B is not 0/0: find WHICH columns differ (one line per column with a mismatch)
/*
SELECT col, COUNT(*) AS lines_differing
FROM #kb k JOIN #asi a ON a.invoice_line_uid = k.invoice_line_uid
CROSS APPLY (VALUES
	('sales_price_home',        CASE WHEN EXISTS (SELECT k.sales_price_home EXCEPT SELECT a.sales_price_home) THEN 1 END),
	('line_other_cost_home',    CASE WHEN EXISTS (SELECT k.line_other_cost_home EXCEPT SELECT a.line_other_cost_home) THEN 1 END),
	('gross_profit_dollars',    CASE WHEN EXISTS (SELECT k.gross_profit_dollars EXCEPT SELECT a.gross_profit_dollars) THEN 1 END),
	('incentive_rewards',       CASE WHEN EXISTS (SELECT k.incentive_rewards EXCEPT SELECT a.incentive_rewards) THEN 1 END),
	('coop_rewards',            CASE WHEN EXISTS (SELECT k.coop_rewards EXCEPT SELECT a.coop_rewards) THEN 1 END),
	('number_of_invoice_lines', CASE WHEN EXISTS (SELECT k.number_of_invoice_lines EXCEPT SELECT a.number_of_invoice_lines) THEN 1 END),
	('manager_id',              CASE WHEN EXISTS (SELECT k.manager_id EXCEPT SELECT a.manager_id) THEN 1 END),
	('manager_name',            CASE WHEN EXISTS (SELECT k.manager_name EXCEPT SELECT a.manager_name) THEN 1 END),
	('product_manager_id',      CASE WHEN EXISTS (SELECT k.product_manager_id EXCEPT SELECT a.product_manager_id) THEN 1 END),
	('gross_inventory_cost_home', CASE WHEN EXISTS (SELECT k.gross_inventory_cost_home EXCEPT SELECT a.gross_inventory_cost_home) THEN 1 END),
	('inflated_sales_price_home', CASE WHEN EXISTS (SELECT k.inflated_sales_price_home EXCEPT SELECT a.inflated_sales_price_home) THEN 1 END)
) v(col, diff)
WHERE v.diff = 1
GROUP BY col;
*/

-------------------------------------------------------------------------------
-- C. The TVFs on their own, across ALL inputs (not just the window above)
-------------------------------------------------------------------------------
-- C1. (removed 2026-10-02: kb_fn_get_product_manager is kept as-is, the view calls it directly)

-- C2. sales manager: every salesrep x commission class pair
SELECT COUNT(*) AS sm_mismatches
FROM (SELECT c.id FROM contacts c WITH (NOLOCK) WHERE c.salesrep = 'Y') r
CROSS JOIN (SELECT commission_class_id FROM item_commission_class_ud UNION SELECT NULL) cc
OUTER APPLY dbo.asi_fnt_get_sales_manager(r.id, cc.commission_class_id) sm
WHERE EXISTS (
	SELECT dbo.kb_fn_get_sales_manager(r.id, cc.commission_class_id, NULL),
	       dbo.kb_fn_get_sales_manager_names(CONVERT(INT, r.id), cc.commission_class_id, NULL)
	EXCEPT
	SELECT sm.sales_manager_id, sm.sales_manager_names);
-- expected: 0  (if contacts.id has non-numeric salesrep ids, CONVERT(INT) errors -- same as the kb_ view would)

-- C3. rebill view port: identical to the kb_ view
SELECT (SELECT COUNT(*) FROM (SELECT * FROM dbo.kb_view_rebill_invoices EXCEPT SELECT * FROM dbo.asi_view_rebill_invoices) x) AS in_kb_not_asi,
       (SELECT COUNT(*) FROM (SELECT * FROM dbo.asi_view_rebill_invoices EXCEPT SELECT * FROM dbo.kb_view_rebill_invoices) y) AS in_asi_not_kb;
-- expected: 0 / 0

-- C4. Dancik cost table copy: identical rows
SELECT (SELECT COUNT(*) FROM (SELECT * FROM dbo.js_view_open_invoice_costs EXCEPT SELECT * FROM dbo.asi_table_dancik_open_invoice_costs) x) AS in_js_not_asi,
       (SELECT COUNT(*) FROM (SELECT * FROM dbo.asi_table_dancik_open_invoice_costs EXCEPT SELECT * FROM dbo.js_view_open_invoice_costs) y) AS in_asi_not_js;
-- expected: 0 / 0

-- C5. direct_flag over ALL history (not just the window): every invoice flagged by the kb_ view, and no others
SELECT (SELECT COUNT(*) FROM (SELECT DISTINCT invoice_no FROM dbo.kb_view_direct_invoices_incl_rebills
                              EXCEPT
                              SELECT DISTINCT CONVERT(VARCHAR(10), CASE WHEN r.invoice_no IS NULL THEN CONVERT(VARCHAR(10), pt.invoice_no) ELSE r.invoice_no END)
                              FROM oe_pick_ticket pt WITH (NOLOCK)
                              LEFT JOIN dbo.asi_view_rebill_invoices r ON CONVERT(VARCHAR(10), pt.invoice_no) = r.original_invoice_no
                              WHERE pt.direct_shipment = 'Y' AND pt.delete_flag = 'N') x) AS direct_in_kb_not_asi;
-- expected: 0 (the reverse direction is covered by B, which compares direct_flag row by row)

-------------------------------------------------------------------------------
-- D. Performance: the Invoice Detail report's own shape, tagged, read from the plan cache.
--    Run D1 and D2 each 2-3 times (first run warms cache), then D3.
--    DBCC FREEPROCCACHE is NOT needed -- the tags isolate the statements.
-------------------------------------------------------------------------------
-- D1
SELECT /* roii_perf_KB */ shrv.invoice_no, shrv.line_no, shrv.customer_id, shrv.item_id, shrv.product_group_desc,
       shrv.price_family_desc, shrv.product_manager_id, shrv.salesrep_id, shrv.salesrep_name, shrv.manager_name,
       shrv.qty_shipped, shrv.unit_price, shrv.sales_price_home, shrv.line_other_cost_home, shrv.gross_profit_dollars,
       shrv.incentive_rewards, shrv.coop_rewards, shrv.rebate_flag, shrv.pricing_method, shrv.direct_flag,
       shrv.sales_location_name, shrv.ship_location_name, shrv.source_location_name, shrv.manager_id
INTO #d1
FROM dbo.kb_sales_history_report_view_roii_costs shrv
WHERE shrv.invoice_date BETWEEN @d_start AND @d_end;
DROP TABLE #d1;

-- D2
SELECT /* roii_perf_ASI */ shrv.invoice_no, shrv.line_no, shrv.customer_id, shrv.item_id, shrv.product_group_desc,
       shrv.price_family_desc, shrv.product_manager_id, shrv.salesrep_id, shrv.salesrep_name, shrv.manager_name,
       shrv.qty_shipped, shrv.unit_price, shrv.sales_price_home, shrv.line_other_cost_home, shrv.gross_profit_dollars,
       shrv.incentive_rewards, shrv.coop_rewards, shrv.rebate_flag, shrv.pricing_method, shrv.direct_flag,
       shrv.sales_location_name, shrv.ship_location_name, shrv.source_location_name, shrv.manager_id
INTO #d2
FROM dbo.asi_sales_history_report_view_roii_costs shrv
WHERE shrv.invoice_date BETWEEN @d_start AND @d_end;
DROP TABLE #d2;

-- D3. The numbers to quote. Scalar UDF cost does NOT show in a statement's own reads -- it is
--     reported separately in sys.dm_exec_function_stats, so that is added for the kb_ side.
SELECT CASE WHEN t.text LIKE '%roii_perf_KB%' THEN 'kb_' ELSE 'asi_' END AS version,
       qs.execution_count,
       qs.total_worker_time   / qs.execution_count / 1000 AS avg_cpu_ms,
       qs.total_logical_reads / qs.execution_count        AS avg_logical_reads,
       qs.last_dop,
       qs.total_elapsed_time  / qs.execution_count / 1000 AS avg_elapsed_ms_IGNORE_ON_PROD
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
WHERE (t.text LIKE '%roii_perf_KB%' OR t.text LIKE '%roii_perf_ASI%')
  AND t.text NOT LIKE '%dm_exec_query_stats%';

SELECT OBJECT_NAME(fs.object_id) AS scalar_udf, fs.execution_count,
       fs.total_worker_time / 1000 AS total_cpu_ms, fs.total_logical_reads
FROM sys.dm_exec_function_stats fs
WHERE fs.database_id = DB_ID()
  AND fs.object_id IN (OBJECT_ID('dbo.kb_fn_get_sales_manager'), OBJECT_ID('dbo.kb_fn_get_sales_manager_names'),
                       OBJECT_ID('dbo.kb_fn_get_product_manager'), OBJECT_ID('dbo.kb_fn_get_contact_name'));
-- kb_ true cost ~= D3 kb_ row + these UDF totals (UDF stats are cumulative since cache load -- note before/after)
