/*
	asi_fnt_invoice_line_rewards / asi_fnt_invoice_price_cost
	Lean, invoice-scoped replacements for kb_view_invoice_line_rewards and the
	~15 columns of kb_sales_history_report_view that the "Invoice Tab Price Cost Detail"
	portal tab (invoice_tab_price_cost_detail.srd) reads.

	Logic is copied from the kb_ views (pricing_option / order_type / parent-line CASEs, advance bill,
	the view's WHERE row filters) - only the columns and joins this tab does not need were dropped.
	Inline TVFs, so the optimizer sees one invoice instead of planning the 43-join view.
	Env: P21Play first. Equivalence proof: Portals\invoice_tab_price_cost_detail\eq.*
*/

CREATE OR ALTER FUNCTION dbo.asi_fnt_invoice_line_rewards (@invoice_no VARCHAR(10))
RETURNS TABLE
AS
RETURN
(
	SELECT
		il.invoice_no
		,il.line_no
		,SUM(COALESCE(rpv.accumulated_coop_dollars,0)) AS coop_rewards
		,SUM(COALESCE(rpv.accumulated_incentive_points,0))
			+ MAX(CASE
				WHEN inv_counter.invoice_count IS NULL THEN COALESCE(ilu.extended_reward, oeu.extended_reward, 0)
				ELSE CASE WHEN ilu.extended_reward IS NOT NULL THEN ilu.extended_reward
					ELSE COALESCE(oeu.extended_reward,0) * (il.qty_shipped/inv_counter.qty_ordered) END
				END) AS incentive_rewards
		,SUM(COALESCE(rpv.accumulated_incentive_points,0)) AS auto_incentive_rewards
		,MAX(CASE
				WHEN inv_counter.invoice_count IS NULL THEN COALESCE(ilu.extended_reward, oeu.extended_reward, 0)
				ELSE CASE WHEN ilu.extended_reward IS NOT NULL THEN ilu.extended_reward
					ELSE COALESCE(oeu.extended_reward,0) * (il.qty_shipped/inv_counter.qty_ordered) END
				END) AS oe_incentive_rewards
	FROM p21_view_invoice_line AS il
	LEFT JOIN (
		-- same derived table as the kb_ view, limited to the order(s) on this invoice
		SELECT ol.order_no, ol.line_no, ol.qty_ordered, COUNT(il2.invoice_no) AS invoice_count
		FROM p21_view_oe_line AS ol
		LEFT JOIN p21_view_invoice_line AS il2
			ON il2.order_no = ol.order_no
			AND il2.oe_line_number = ol.line_no
		WHERE ol.order_no IN (SELECT x.order_no FROM p21_view_invoice_line AS x WHERE x.invoice_no = @invoice_no)
		GROUP BY ol.order_no, ol.line_no, ol.qty_ordered
		HAVING COUNT(il2.invoice_no) > 1
	) AS inv_counter
		ON inv_counter.order_no = il.order_no
		AND inv_counter.line_no = il.oe_line_number
	LEFT JOIN p21_view_rewards_program_values AS rpv
		ON rpv.invoice_line_uid = il.invoice_line_uid
		AND rpv.row_status_flag = 704
	LEFT JOIN oe_line_ud AS oeu WITH (NOLOCK)
		ON il.order_no = oeu.order_no
		AND il.oe_line_number = oeu.line_no
	LEFT JOIN invoice_line_ud AS ilu WITH (NOLOCK)
		ON il.invoice_no = ilu.invoice_no
		AND il.line_no = ilu.line_no
	WHERE il.invoice_no = @invoice_no
		AND (COALESCE(rpv.accumulated_coop_dollars,0) <> 0
			OR COALESCE(rpv.accumulated_incentive_points,0)
				+ CASE
					WHEN inv_counter.invoice_count IS NULL THEN COALESCE(ilu.extended_reward, oeu.extended_reward, 0)
					ELSE COALESCE(ilu.extended_reward, oeu.extended_reward, 0) * (il.qty_shipped/inv_counter.qty_ordered)
				END <> 0)
	GROUP BY il.invoice_no, il.line_no
)
GO

CREATE OR ALTER FUNCTION dbo.asi_fnt_invoice_price_cost (@invoice_no VARCHAR(10))
RETURNS TABLE
AS
RETURN
(
	SELECT
		il.invoice_line_uid
		,il.invoice_no
		,il.line_no
		,il.qty_shipped
		,il.pricing_unit
		,il.inv_mast_uid
		,im.base_unit
		,COALESCE(il.pricing_unit_size, ol.pricing_unit_size, 1) AS pricing_unit_size
		,CASE
			WHEN il.qty_shipped IS NULL THEN il.unit_price
			WHEN ROUND(COALESCE(rw.incentive_rewards, 0.0000), 4) = 0.0000 THEN il.unit_price
			ELSE ROUND(il.unit_price - (rw.incentive_rewards / (il.qty_shipped / il.pricing_unit_size)), 2)
		END AS unit_price
		,(CASE COALESCE(ab.advance_bill, 'N')
			WHEN 'Y' THEN ((il.qty_shipped * (il.unit_price_home / COALESCE(il.pricing_unit_size,1))))
			WHEN 'N' THEN
				CASE COALESCE(ol.pricing_option,0)
					WHEN 1 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN 0 ELSE il.extended_price_home END)
					WHEN 2 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN il.extended_price_home ELSE 0 END)
					WHEN 3 THEN (CASE il.invoice_line_uid_parent WHEN 0 THEN il.extended_price_home ELSE 0 END)
					WHEN 4 THEN 0
					WHEN 0 THEN (
						CASE oh.order_type
							WHEN 1706 THEN (CASE WHEN il.invoice_line_type = 0 THEN drv.sum_price_home ELSE il.extended_price_home END)
							ELSE il.extended_price_home
						END)
					ELSE il.extended_price_home
				END
		END) AS inflated_sales_price_home
		,(CASE COALESCE(ab.advance_bill, 'N')
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
		END) AS sales_price_home
		,c.deflated_line_other_cost_home
		,c.line_other_cost_home
		,CASE COALESCE(ab.advance_bill, 'N')
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
		END - c.line_other_cost_home AS gross_profit_dollars
		,CASE
			WHEN COALESCE(ol.manual_price_overide, 'N') = 'Y' THEN 'Manual Override'
			ELSE CASE
				WHEN COALESCE(il.job_price_line_uid, 0) = 0 THEN CASE WHEN pp.description IS NULL THEN 'Unknown' ELSE pp.description END
				ELSE 'Contract'
			END
		END AS pricing_method
		,ol.system_calc_unit_price
		,COALESCE(oh.job_name,'') AS job_name
		,COALESCE(il.cost_price_page_uid, ol.cost_price_page_uid, ol.price_page_uid) AS cost_price_page_uid
		,COALESCE(ol.oe_line_uid, 0) AS oe_line_uid
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
	LEFT JOIN inv_mast AS im WITH (NOLOCK)
		ON il.inv_mast_uid = im.inv_mast_uid
	LEFT JOIN price_page AS pp WITH (NOLOCK)
		ON pp.price_page_uid = COALESCE(il.cost_price_page_uid, ol.cost_price_page_uid, ol.price_page_uid)
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
			AND x.invoice_no = @invoice_no
		GROUP BY x.invoice_line_uid_parent
	) AS drv
		ON drv.invoice_line_uid_parent = il.invoice_line_uid
	LEFT JOIN dbo.asi_fnt_invoice_line_rewards(@invoice_no) AS rw
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
			,CASE COALESCE(ol.pricing_option, 0)
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
			END AS deflated_line_other_cost_home
	) AS c
	WHERE ih.invoice_no = @invoice_no
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
)
GO
