USE [P21Play]
GO

/*
=====================================================================================================
 dbo.asi_table_dancik_open_invoice_costs
 Static copy of dbo.js_view_open_invoice_costs -- despite the name, that object is a TABLE (created
 2022-09-19 by JS): corrected unit costs for open invoices imported from Dancik, invoice dates
 2014-10-10 .. 2017-07-06, 17,624 lines. It never changes, so a one-time copy is the whole replacement.
 The js_ table is left in place.
 Used by: asi_sales_history_report_view_roii_costs (line_other_cost_home / gross_profit_dollars).

 SELECT INTO keeps the source column types exactly. Safe to re-run: skips the copy if the table exists.
 Created 2026-10-02 Mark Goldyn.
=====================================================================================================
*/
SET NOCOUNT ON;

IF OBJECT_ID('dbo.asi_table_dancik_open_invoice_costs', 'U') IS NULL
BEGIN
	SELECT *
	INTO dbo.asi_table_dancik_open_invoice_costs
	FROM dbo.js_view_open_invoice_costs;

	PRINT CONCAT('Copied ', @@ROWCOUNT, ' rows.');
END
ELSE
	PRINT 'dbo.asi_table_dancik_open_invoice_costs already exists -- copy skipped.';
GO

-- The view joins on (invoice_no, line_no). Unique if the source is; otherwise fall back to a
-- non-unique index and report the duplicates (they would also duplicate rows in the kb_ view).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.asi_table_dancik_open_invoice_costs') AND index_id = 1)
BEGIN
	IF EXISTS (SELECT invoice_no, line_no FROM dbo.asi_table_dancik_open_invoice_costs
	           GROUP BY invoice_no, line_no HAVING COUNT(*) > 1)
	BEGIN
		CREATE CLUSTERED INDEX cx_asi_table_dancik_open_invoice_costs
			ON dbo.asi_table_dancik_open_invoice_costs (invoice_no, line_no);
		PRINT 'WARNING: duplicate (invoice_no, line_no) keys -- non-unique index created. Duplicates:';
		SELECT invoice_no, line_no, COUNT(*) AS copies
		FROM dbo.asi_table_dancik_open_invoice_costs
		GROUP BY invoice_no, line_no HAVING COUNT(*) > 1;
	END
	ELSE
		CREATE UNIQUE CLUSTERED INDEX cx_asi_table_dancik_open_invoice_costs
			ON dbo.asi_table_dancik_open_invoice_costs (invoice_no, line_no);
END
GO

GRANT SELECT ON dbo.asi_table_dancik_open_invoice_costs TO p21_application_role
GO
GRANT SELECT ON dbo.asi_table_dancik_open_invoice_costs TO PxxiUser
GO

-- check: both counts should match (17,624 in Play on 2026-10-02)
SELECT (SELECT COUNT(*) FROM dbo.js_view_open_invoice_costs) AS js_rows,
       (SELECT COUNT(*) FROM dbo.asi_table_dancik_open_invoice_costs) AS asi_rows;
