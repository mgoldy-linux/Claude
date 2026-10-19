/*
	asi_fnt_customer_period_sales
	Customer-scoped replacement for the two OUTER APPLY blocks over kb_sales_history_report_view in the
	"Customer Tab Sales" portal tab (customer_tab_sales.srd). Returns ONE row per (year_for_period, period):
	SUM(sales_price_home), SUM(gross_profit_dollars) for a customer, from year @from_year forward.
	Price/cost logic is the same as asi_fnt_invoice_price_cost (copied from kb_sales_history_report_view,
	same row filters); rewards are the asi_fnt_invoice_line_rewards logic scoped to this customer's invoices.
	Env: P21Play first.
*/
CREATE OR ALTER FUNCTION dbo.asi_fnt_customer_period_sales (@company_id VARCHAR(8), @customer_id DECIMAL(19,0), @from_year DECIMAL(4,0))
RETURNS TABLE
AS
RETURN
(
	SELECT
		ih.year_for_period
		,ih.period
		,SUM(sp.sales_price_home) AS sales_price_home
		,SUM(sp.sales_price_home - c.line_other_cost_home) AS gross_profit_dollars
	FROM invoice_hdr AS ih WITH (NOLOCK)
	INNER JOIN p21_view_invoice_line AS il WITH (NOLOCK)
		ON ih.invoice_no = il.invoice_no
	INNER JOIN company AS co WITH (NOLOCK)
		ON ih.company_no = co.company_id
	INNER JOIN customer AS cu WITH (NOLOCK)
		ON ih.sold_to_customer_id = cu.customer_id
		AND ih.company_no = cu.company_id
	INNER JOIN address_history AS ah WITH (NOLOCK)
		ON ih.sold_to_ah_uid = ah.address_history_uid
	INNER JOIN currency_hdr AS ch WITH (NOLOCK)
		ON ch.currency_id = cu.currency_id
	LEFT JOIN invoice_hdr_salesrep AS ihs WITH (NOLOCK)
		ON ihs.invoice_number = ih.invoice_no
		AND ihs.primary_salesrep = 'Y'
	LEFT JOIN oe_hdr AS oh WITH (NOLOCK)
		ON ih.order_no = oh.order_no
	LEFT JOIN oe_hdr_advance_billing AS ab WITH (NOLOCK)
		ON ab.order_no = ih.order_no
	LEFT JOIN inv_loc AS il1 WITH (NOLOCK)
		ON il.inv_mast_uid = il1.inv_mast_uid
		AND ih.sales_location_id = il1.location_id
		AND ih.company_no = il1.company_id
	LEFT JOIN inv_loc AS il100 WITH (NOLOCK)
		ON il100.location_id = 100 AND il100.company_id = ih.company_no
		AND il100.inv_mast_uid = il.inv_mast_uid
	LEFT JOIN product_group AS pg WITH (NOLOCK)
		ON il.company_id = pg.company_id
		AND COALESCE(
				CASE il1.product_group_id WHEN '' THEN NULL ELSE il1.product_group_id END,
				CASE il100.product_group_id WHEN '' THEN NULL ELSE il100.product_group_id END
			) = pg.product_group_id
	LEFT JOIN oe_line AS ol WITH (NOLOCK)
		ON il.oe_line_number = ol.line_no
		AND il.order_no = ol.order_no
		AND il.invoice_line_type <> 1577
	LEFT JOIN (
		SELECT
			SUM(x.extended_price_home) AS sum_price_home
			,SUM(CASE x.invoice_line_type
				WHEN 1577 THEN x.other_cost_home * x.hours_worked
				WHEN 1719 THEN x.other_cost_home * x.qty_shipped
			END) AS sum_other_cost_home
			,x.invoice_line_uid_parent
		FROM p21_view_invoice_line AS x
		WHERE x.invoice_line_type IN (1719, 1577)
			AND x.invoice_no IN (SELECT h.invoice_no FROM invoice_hdr AS h
				WHERE h.sold_to_customer_id = @customer_id AND h.company_no = @company_id AND h.year_for_period >= @from_year)
		GROUP BY x.invoice_line_uid_parent
	) AS drv
		ON drv.invoice_line_uid_parent = il.invoice_line_uid
	LEFT JOIN (
		-- asi_fnt_invoice_line_rewards logic, for every invoice of this customer
		SELECT
			r.invoice_no
			,r.line_no
			,SUM(COALESCE(rpv.accumulated_incentive_points,0))
				+ MAX(CASE
					WHEN inv_counter.invoice_count IS NULL THEN COALESCE(ilu.extended_reward, oeu.extended_reward, 0)
					ELSE CASE WHEN ilu.extended_reward IS NOT NULL THEN ilu.extended_reward
						ELSE COALESCE(oeu.extended_reward,0) * (r.qty_shipped/inv_counter.qty_ordered) END
					END) AS incentive_rewards
		FROM p21_view_invoice_line AS r
		LEFT JOIN (
			SELECT ol2.order_no, ol2.line_no, ol2.qty_ordered, COUNT(il2.invoice_no) AS invoice_count
			FROM p21_view_oe_line AS ol2
			LEFT JOIN p21_view_invoice_line AS il2
				ON il2.order_no = ol2.order_no
				AND il2.oe_line_number = ol2.line_no
			WHERE ol2.order_no IN (SELECT x.order_no FROM p21_view_invoice_line AS x
				WHERE x.invoice_no IN (SELECT h.invoice_no FROM invoice_hdr AS h
					WHERE h.sold_to_customer_id = @customer_id AND h.company_no = @company_id AND h.year_for_period >= @from_year))
			GROUP BY ol2.order_no, ol2.line_no, ol2.qty_ordered
			HAVING COUNT(il2.invoice_no) > 1
		) AS inv_counter
			ON inv_counter.order_no = r.order_no
			AND inv_counter.line_no = r.oe_line_number
		LEFT JOIN p21_view_rewards_program_values AS rpv
			ON rpv.invoice_line_uid = r.invoice_line_uid
			AND rpv.row_status_flag = 704
		LEFT JOIN oe_line_ud AS oeu WITH (NOLOCK)
			ON r.order_no = oeu.order_no
			AND r.oe_line_number = oeu.line_no
		LEFT JOIN invoice_line_ud AS ilu WITH (NOLOCK)
			ON r.invoice_no = ilu.invoice_no
			AND r.line_no = ilu.line_no
		WHERE r.invoice_no IN (SELECT h.invoice_no FROM invoice_hdr AS h
				WHERE h.sold_to_customer_id = @customer_id AND h.company_no = @company_id AND h.year_for_period >= @from_year)
			AND (COALESCE(rpv.accumulated_coop_dollars,0) <> 0
				OR COALESCE(rpv.accumulated_incentive_points,0)
					+ CASE
						WHEN inv_counter.invoice_count IS NULL THEN COALESCE(ilu.extended_reward, oeu.extended_reward, 0)
						ELSE COALESCE(ilu.extended_reward, oeu.extended_reward, 0) * (r.qty_shipped/inv_counter.qty_ordered)
					END <> 0)
		GROUP BY r.invoice_no, r.line_no
	) AS rw
		ON il.invoice_no = rw.invoice_no
		AND il.line_no = rw.line_no
	CROSS APPLY (
		SELECT
			CASE COALESCE(ol.pricing_option, 0)
				WHEN 1 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN 0 ELSE il.other_cost_home * il.qty_shipped END)
				WHEN 2 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN il.other_cost_home * il.qty_shipped ELSE 0 END)
				WHEN 3 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN il.other_cost_home * il.qty_shipped ELSE 0 END)
				WHEN 4 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN il.other_cost_home * il.qty_shipped ELSE 0 END)
				WHEN 0 THEN (
					CASE WHEN oh.order_type = 1706 THEN (
						CASE il.invoice_line_type
							WHEN 1577 THEN il.other_cost_home * il.hours_worked
							WHEN 1719 THEN il.other_cost_home * il.qty_shipped
							ELSE drv.sum_other_cost_home
						END)
					ELSE il.other_cost_home * il.qty_shipped END)
				ELSE il.other_cost_home * il.qty_shipped
			END AS line_other_cost_home
	) AS c
	CROSS APPLY (
		SELECT
			CASE COALESCE(ab.advance_bill, 'N')
				WHEN 'Y' THEN ((il.qty_shipped * (il.unit_price_home / COALESCE(il.pricing_unit_size,1))) - COALESCE(rw.incentive_rewards, 0))
				WHEN 'N' THEN
					CASE COALESCE(ol.pricing_option,0)
						WHEN 1 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN 0 ELSE il.extended_price_home - COALESCE(rw.incentive_rewards, 0) END)
						WHEN 2 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN il.extended_price_home - COALESCE(rw.incentive_rewards, 0) ELSE 0 END)
						WHEN 3 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN il.extended_price_home - COALESCE(rw.incentive_rewards, 0) ELSE 0 END)
						WHEN 4 THEN 0
						WHEN 0 THEN (
							CASE oh.order_type
								WHEN 1706 THEN (CASE WHEN il.invoice_line_type = 0 THEN drv.sum_price_home - COALESCE(rw.incentive_rewards, 0)
									ELSE il.extended_price_home - COALESCE(rw.incentive_rewards, 0) END)
								ELSE il.extended_price_home - COALESCE(rw.incentive_rewards, 0)
							END)
						ELSE il.extended_price_home - COALESCE(rw.incentive_rewards, 0)
					END
			END AS sales_price_home
	) AS sp
	WHERE ih.sold_to_customer_id = @customer_id
		AND ih.company_no = @company_id
		AND ih.year_for_period >= @from_year
		AND ih.approved = 'Y'
		AND (ISNULL(ih.source_type_cd,0) <> 1661
			OR il.item_id NOT IN ('DELIVERY','DISC','FUEL CHG','FUND','HAND','MISC','OVERPAYMENT','INBOUND FUEL SURCHARGE',
				'BALANCING_ITEM','FREIGHT_ITEM','HANDLING_ITEM'))
		AND (ISNULL(ih.source_type_cd,0) = 1661 OR ih.invoice_class NOT IN ('Z'))
		AND ih.invoice_class NOT IN ('FINANCE')
		AND il.item_id <> 'FRT OUT'
		AND COALESCE(pg.product_group_id,'') NOT IN ('OCI','OCHARGE')
		AND il.inv_mast_uid <> 0
		AND ih.invoice_adjustment_type NOT IN ('B','T','X','R','W','A','P','Z','Y')
		AND ih.consolidated <> 'C'
		AND il.tax_item = 'N'
		AND ih.original_document_type <> 'T'
		AND il.invoice_line_type NOT IN (928, 929, 930, 3)
		AND il.item_id NOT IN ('DOWNPAYMENT','PREPAYMENT','cash deposit')
		AND il.item_id <> 'ADVANCE BILL AMOUNT'
		AND ihs.primary_salesrep = 'Y'
		AND (il.qty_shipped > 0.0000
			OR il.qty_shipped < 0.0000
			OR (il.invoice_line_type = 1577
				AND (COALESCE(il.hours_worked, 0) <> 0 OR il.extended_price <> 0)))
		AND ((COALESCE(ol.lot_bill,'N') = 'N')
			OR (ol.lot_bill = 'Y' AND il.invoice_line_uid_parent = 0 AND il.invoice_line_type = 4))
	GROUP BY ih.year_for_period, ih.period
)
GO
