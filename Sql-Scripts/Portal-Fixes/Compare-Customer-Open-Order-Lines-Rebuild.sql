/*
    Equivalence check: original customer_tab_open_order_lines.srd retrieve= SQL
    (kb_view_open_orders based) vs. asi_view_customer_open_order_lines (rebuild).

    KNOWN, EXPECTED DIFFERENCES -- do not read these as bugs in the rebuild:
      - gp_pct: original had a third fallback branch sourced from
        kb_sales_history_report_view (no native replacement exists -- see the view's
        own header comments, note 2). The rebuild's gp_pct will differ on any row
        where that branch fired in the original.
      - salesrep_id: original's COALESCE had no NULLIF(...,0) guard, so it could
        surface a 0 where the rebuild correctly falls through to the next source
        (same class of bug SA-48732 found: 294 blanks -> 0 after the fix).

    Run part 1 first (full 27-column compare) -- expect nonzero diffs from the two
    columns above. Then run part 2, which excludes those two columns, to confirm
    everything ELSE lines up exactly. If part 2 is not 0/0, that's a real problem
    worth chasing; parts 3 and 4 isolate the two known-different columns so you can
    eyeball whether the differences look like the expected cases or something else.
*/

DECLARE @cust_id INT = 1048980;  -- set to a real customer_id with open order history

-- ============================================================================
-- Shared CTEs
-- ============================================================================
;WITH old_q AS (
	SELECT
		p21_view_oe_hdr.order_no,
		p21_view_oe_line.line_no,
		COALESCE(invo_line.invoice_no, '') AS invoice_no,
		p21_view_oe_hdr.order_date,
		p21_view_oe_hdr.po_no AS customer_po_no,
		p21_view_oe_line.item_id,
		p21_view_inv_mast.extended_desc,
		p21_view_oe_line.qty_ordered,
		kb_view_open_orders.qty_open,
		CASE ISNULL(p21_view_oe_line.full_rolled_item_cd, '')
			WHEN 3563 THEN 'Cut'
			WHEN 3561 THEN 'Roll'
			WHEN 3562 THEN 'Balance'
			ELSE ''
		END AS roll_type,
		p21_view_oe_line.unit_price,
		CASE manual_price_overide
			WHEN 'Y' THEN p21_view_oe_line.system_calc_unit_price
			ELSE NULL
		END AS system_calc_unit_price,
		p21_view_oe_line.extended_price,
		CASE WHEN invo_line.invoice_no IS NULL THEN
			CASE p21_view_oe_line.unit_price WHEN 0 THEN NULL
				ELSE (p21_view_oe_line.unit_price - p21_view_oe_line.commission_cost) / p21_view_oe_line.unit_price END
		ELSE
			CASE WHEN mgn_invo_line.sales_price_home IS NULL
				THEN CASE invo_line.price WHEN 0 THEN NULL ELSE ((invo_line.price - invo_line.cost) / invo_line.price) END
				ELSE CASE mgn_invo_line.sales_price_home WHEN 0 THEN NULL ELSE (mgn_invo_line.gross_profit_dollars / mgn_invo_line.sales_price_home) END
			END
		END AS gp_pct,
		p21_view_oe_line.disposition,
		p21_view_oe_hdr.rma_flag,
		p21_view_oe_hdr.cancel_flag,
		p21_view_oe_hdr.validation_status,
		p21_view_oe_hdr.approved,
		p21_view_oe_line.complete,
		p21_view_oe_line.required_date,
		p21_view_oe_hdr.taker,
		p21_view_oe_hdr.job_name,
		COALESCE(mgn_invo_line.salesrep_id, oe_line_ud.updated_salesrep_id, oe_line_ud.oe_salesrep_id) AS salesrep_id,
		kb_view_salesrep.salesrep_name,
		p21_view_oe_hdr.address_id AS ship_to_id,
		CASE p21_view_inv_mast.default_price_family_uid WHEN 3 THEN 'CCS' WHEN 2 THEN 'All Tile' ELSE '' END AS price_family
	FROM kb_view_open_orders
		INNER JOIN p21_view_oe_hdr ON kb_view_open_orders.order_no = p21_view_oe_hdr.order_no
		INNER JOIN p21_view_customer
			ON p21_view_oe_hdr.company_id = p21_view_customer.company_id
			AND p21_view_oe_hdr.customer_id = p21_view_customer.customer_id
		INNER JOIN p21_view_oe_line
			ON (p21_view_oe_line.order_no = kb_view_open_orders.order_no)
			AND kb_view_open_orders.line_no = p21_view_oe_line.line_no
			AND (p21_view_oe_line.parent_oe_line_uid = 0)
		LEFT JOIN oe_line_ud WITH (NOLOCK)
			ON oe_line_ud.order_no = p21_view_oe_hdr.order_no
			AND oe_line_ud.line_no = p21_view_oe_line.line_no
		LEFT JOIN (
			SELECT
				kb_sales_history_report_view.order_no,
				kb_sales_history_report_view.oe_line_number,
				kb_sales_history_report_view.salesrep_id,
				SUM(kb_sales_history_report_view.sales_price_home)     AS sales_price_home,
				SUM(kb_sales_history_report_view.gross_profit_dollars) AS gross_profit_dollars
			FROM kb_sales_history_report_view
			GROUP BY
				kb_sales_history_report_view.order_no, kb_sales_history_report_view.oe_line_number, kb_sales_history_report_view.salesrep_id
		) AS mgn_invo_line
			ON mgn_invo_line.order_no = p21_view_oe_line.order_no
			AND mgn_invo_line.oe_line_number = p21_view_oe_line.line_no
			AND p21_view_oe_line.parent_oe_line_uid = 0
		LEFT JOIN (
			SELECT
				p21_view_invoice_line.order_no,
				p21_view_invoice_line.oe_line_number,
				MAX(p21_view_invoice_line.invoice_no) AS invoice_no,
				SUM(unit_price_home)      AS price,
				SUM(commission_cost_home) AS cost
			FROM p21_view_invoice_line
			GROUP BY
				p21_view_invoice_line.order_no, p21_view_invoice_line.oe_line_number
		) AS invo_line
			ON invo_line.order_no = p21_view_oe_line.order_no
			AND invo_line.oe_line_number = p21_view_oe_line.line_no
			AND p21_view_oe_line.parent_oe_line_uid = 0
		LEFT JOIN p21_view_inv_mast
			ON p21_view_inv_mast.inv_mast_uid = p21_view_oe_line.inv_mast_uid
		LEFT JOIN kb_view_salesrep
			ON kb_view_salesrep.salesrep_id = COALESCE(mgn_invo_line.salesrep_id, oe_line_ud.updated_salesrep_id, oe_line_ud.oe_salesrep_id)
	WHERE
		p21_view_oe_hdr.delete_flag = 'N'
		AND p21_view_oe_hdr.projected_order = 'N'
		AND p21_view_oe_line.delete_flag = 'N'
		AND p21_view_oe_hdr.customer_id = ISNULL(@cust_id, 1)
),
new_q AS (
	SELECT
		order_no, line_no, invoice_no, order_date, customer_po_no, item_id, extended_desc,
		qty_ordered, qty_open, roll_type, unit_price, system_calc_unit_price, extended_price,
		gp_pct, disposition, rma_flag, cancel_flag, validation_status, approved, complete,
		required_date, taker, job_name, salesrep_id, salesrep_name, ship_to_id, price_family
	FROM dbo.asi_view_customer_open_order_lines
	WHERE customer_id = @cust_id
)

-- ============================================================================
-- Part 1: full 27-column compare -- expect nonzero diffs (see header)
-- ============================================================================
SELECT
	(SELECT COUNT(*) FROM old_q) AS old_rows,
	(SELECT COUNT(*) FROM new_q) AS new_rows,
	(SELECT COUNT(*) FROM (SELECT * FROM old_q EXCEPT SELECT * FROM new_q) a) AS in_old_not_new,
	(SELECT COUNT(*) FROM (SELECT * FROM new_q EXCEPT SELECT * FROM old_q) b) AS in_new_not_old;

-- ============================================================================
-- Part 2: same compare EXCLUDING gp_pct and salesrep_id -- this SHOULD be 0/0.
-- If it isn't, something other than the two known gaps is wrong.
-- ============================================================================
/*;WITH old_q AS (
	SELECT
		p21_view_oe_hdr.order_no,
		p21_view_oe_line.line_no,
		COALESCE(invo_line.invoice_no, '') AS invoice_no,
		p21_view_oe_hdr.order_date,
		p21_view_oe_hdr.po_no AS customer_po_no,
		p21_view_oe_line.item_id,
		p21_view_inv_mast.extended_desc,
		p21_view_oe_line.qty_ordered,
		kb_view_open_orders.qty_open,
		CASE ISNULL(p21_view_oe_line.full_rolled_item_cd, '')
			WHEN 3563 THEN 'Cut'
			WHEN 3561 THEN 'Roll'
			WHEN 3562 THEN 'Balance'
			ELSE ''
		END AS roll_type,
		p21_view_oe_line.unit_price,
		CASE manual_price_overide
			WHEN 'Y' THEN p21_view_oe_line.system_calc_unit_price
			ELSE NULL
		END AS system_calc_unit_price,
		p21_view_oe_line.extended_price,
		p21_view_oe_line.disposition,
		p21_view_oe_hdr.rma_flag,
		p21_view_oe_hdr.cancel_flag,
		p21_view_oe_hdr.validation_status,
		p21_view_oe_hdr.approved,
		p21_view_oe_line.complete,
		p21_view_oe_line.required_date,
		p21_view_oe_hdr.taker,
		p21_view_oe_hdr.job_name,
		kb_view_salesrep.salesrep_name,
		p21_view_oe_hdr.address_id AS ship_to_id,
		CASE p21_view_inv_mast.default_price_family_uid WHEN 3 THEN 'CCS' WHEN 2 THEN 'All Tile' ELSE '' END AS price_family
	FROM kb_view_open_orders
		INNER JOIN p21_view_oe_hdr ON kb_view_open_orders.order_no = p21_view_oe_hdr.order_no
		INNER JOIN p21_view_customer
			ON p21_view_oe_hdr.company_id = p21_view_customer.company_id
			AND p21_view_oe_hdr.customer_id = p21_view_customer.customer_id
		INNER JOIN p21_view_oe_line
			ON (p21_view_oe_line.order_no = kb_view_open_orders.order_no)
			AND kb_view_open_orders.line_no = p21_view_oe_line.line_no
			AND (p21_view_oe_line.parent_oe_line_uid = 0)
		LEFT JOIN oe_line_ud WITH (NOLOCK)
			ON oe_line_ud.order_no = p21_view_oe_hdr.order_no
			AND oe_line_ud.line_no = p21_view_oe_line.line_no
		LEFT JOIN (
			SELECT
				p21_view_invoice_line.order_no,
				p21_view_invoice_line.oe_line_number,
				MAX(p21_view_invoice_line.invoice_no) AS invoice_no,
				SUM(unit_price_home)      AS price,
				SUM(commission_cost_home) AS cost
			FROM p21_view_invoice_line
			GROUP BY
				p21_view_invoice_line.order_no, p21_view_invoice_line.oe_line_number
		) AS invo_line
			ON invo_line.order_no = p21_view_oe_line.order_no
			AND invo_line.oe_line_number = p21_view_oe_line.line_no
			AND p21_view_oe_line.parent_oe_line_uid = 0
		LEFT JOIN p21_view_inv_mast
			ON p21_view_inv_mast.inv_mast_uid = p21_view_oe_line.inv_mast_uid
		LEFT JOIN (
			SELECT
				kb_sales_history_report_view.order_no,
				kb_sales_history_report_view.oe_line_number,
				kb_sales_history_report_view.salesrep_id
			FROM kb_sales_history_report_view
			GROUP BY kb_sales_history_report_view.order_no, kb_sales_history_report_view.oe_line_number, kb_sales_history_report_view.salesrep_id
		) AS mgn_invo_line
			ON mgn_invo_line.order_no = p21_view_oe_line.order_no
			AND mgn_invo_line.oe_line_number = p21_view_oe_line.line_no
			AND p21_view_oe_line.parent_oe_line_uid = 0
		LEFT JOIN kb_view_salesrep
			ON kb_view_salesrep.salesrep_id = COALESCE(mgn_invo_line.salesrep_id, oe_line_ud.updated_salesrep_id, oe_line_ud.oe_salesrep_id)
	WHERE
		p21_view_oe_hdr.delete_flag = 'N'
		AND p21_view_oe_hdr.projected_order = 'N'
		AND p21_view_oe_line.delete_flag = 'N'
		AND p21_view_oe_hdr.customer_id = ISNULL(@cust_id, 1)
),
new_q AS (
	SELECT
		order_no, line_no, invoice_no, order_date, customer_po_no, item_id, extended_desc,
		qty_ordered, qty_open, roll_type, unit_price, system_calc_unit_price, extended_price,
		disposition, rma_flag, cancel_flag, validation_status, approved, complete,
		required_date, taker, job_name, salesrep_name, ship_to_id, price_family
	FROM dbo.asi_view_customer_open_order_lines
	WHERE customer_id = @cust_id
)
SELECT
	(SELECT COUNT(*) FROM old_q) AS old_rows,
	(SELECT COUNT(*) FROM new_q) AS new_rows,
	(SELECT COUNT(*) FROM (SELECT * FROM old_q EXCEPT SELECT * FROM new_q) a) AS in_old_not_new,
	(SELECT COUNT(*) FROM (SELECT * FROM new_q EXCEPT SELECT * FROM old_q) b) AS in_new_not_old;
*/
-- ============================================================================
-- Parts 3 and 4 need old_q/new_q AS DEFINED IN PART 1 (they include gp_pct and
-- salesrep_id -- Part 2's versions strip those columns out). Re-run Part 1's
-- ;WITH block immediately before either of these, then uncomment and run.
--
-- Part 3: isolate gp_pct differences -- eyeball whether they trace to the dropped
-- kb_sales_history_report_view fallback (expected) or look arbitrary (not expected)
-- ============================================================================
--SELECT o.order_no, o.line_no, o.gp_pct AS old_gp_pct, n.gp_pct AS new_gp_pct
--FROM old_q o
--JOIN new_q n ON n.order_no = o.order_no AND n.line_no = o.line_no
--WHERE ISNULL(o.gp_pct, -999) <> ISNULL(n.gp_pct, -999);

-- ============================================================================
-- Part 4: isolate salesrep_id differences -- expect only cases where old = 0 and
-- new is NULL or a different (correctly-resolved) id
-- ============================================================================
--SELECT o.order_no, o.line_no, o.salesrep_id AS old_salesrep_id, n.salesrep_id AS new_salesrep_id
--FROM old_q o
--JOIN new_q n ON n.order_no = o.order_no AND n.line_no = o.line_no
--WHERE ISNULL(o.salesrep_id, -1) <> ISNULL(n.salesrep_id, -1);

-- ============================================================================
-- Part 5 (also needs Part 1's old_q/new_q): 2026-09-25 finding on customer 1048980 --
-- old=10, new=11 rows, and Part 1 and Part 2 gave the SAME diff count, meaning the
-- extra row is a genuinely different order_no/line_no (not a gp_pct/salesrep_id value
-- mismatch on an otherwise-matching row). Find it, and check for join fan-out.
-- ============================================================================
-- 5a: the row(s) new_q has that old_q doesn't, by KEY (not full-row) -- if this is
-- empty while Part 1 still shows in_new_not_old > 0, it's a duplicate (5b), not a new row
-- SELECT n.*
-- FROM new_q n
-- WHERE NOT EXISTS (SELECT 1 FROM old_q o WHERE o.order_no = n.order_no AND o.line_no = n.line_no);

-- 5b: duplicate order_no/line_no within new_q -- would mean god or invo_line is
-- matching more than one row per line (join fan-out), not a filter difference
--SELECT order_no, line_no, COUNT(*) AS cnt
--FROM new_q
--GROUP BY order_no, line_no
--HAVING COUNT(*) > 1;
