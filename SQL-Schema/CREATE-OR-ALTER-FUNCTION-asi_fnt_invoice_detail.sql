USE [P21Play]
GO

/*
=====================================================================================================
 dbo.asi_fnt_invoice_detail(@d_start, @d_end)  -- inline table-valued function
 Purpose-built source for the SSRS report "Invoice Detail" (Company Reports/Sales).
 Replaces its FROM kb_sales_history_report_view_roii_costs -- a 197-column, all-history view --
 with only the 45 columns that report's query reads, built only for the requested date range.

 Report change (one line):
     FROM kb_sales_history_report_view_roii_costs AS shrv
  -> FROM dbo.asi_fnt_invoice_detail(@d_start, @d_end) AS shrv
 Column names are unchanged, so the report's other joins, filters and layout stay as they are.

 Logic is the kb_ view's, unchanged -- taken from asi_sales_history_report_view_roii_costs (drafted 2026-10-02):
   pricing (sales_price_home / line_other_cost_home / gross_profit_dollars), rewards, direct-ship,
   Dancik cost overrides, salesrep + sales manager. Row filters (WHERE) identical to the kb_ view.
 Joins the report never reads are not here (branch, supplier, vendor, job/contract, progress billing,
 lot billing, item classes, UOM, ...). If one of those multiplied rows in the kb_ view, the report was
 showing duplicate lines -- 03-verify checks for that.

 Depends on: dbo.asi_fnt_get_sales_manager, dbo.asi_view_rebill_invoices,
             dbo.asi_table_dancik_open_invoice_costs (create those first).
 Still kb_ on purpose: dbo.kb_fn_get_product_manager (until the P21 Product Manager role + users_ud
             assignments are populated); kb_table_sales_manager_values(_all) inside asi_fnt_get_sales_manager.
 Created 2026-10-02 Mark Goldyn.
=====================================================================================================
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER FUNCTION dbo.asi_fnt_invoice_detail
(
	@d_start DATETIME,
	@d_end   DATETIME
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		invoice_hdr.invoice_date
		,invoice_hdr.invoice_no
		,invoice_hdr.order_no
		,invoice_hdr.sold_to_customer_id AS customer_id
		,customer.customer_name
		,ISNULL(customer_ud.chain,'(None)') AS chain
		,invoice_hdr.po_no
		,COALESCE(invoice_hdr.sales_location_id, oe_hdr.location_id, 0) AS sales_location_id
		,CASE WHEN direct.invoice_no IS NULL THEN 'N' ELSE 'Y' END AS direct_flag
		,oe_hdr.order_date
		,COALESCE(oe_hdr.taker, 'N/A') AS taker
		,COALESCE(oe_hdr.job_name,'') AS job_name
		,p21_view_invoice_line.qty_shipped
		,COALESCE(inv_mast.item_id,p21_view_invoice_line.item_id) AS item_id
		,p21_view_invoice_line.line_no
		,p21_view_invoice_line.oe_line_number
		,p21_view_invoice_line.pricing_unit
		,p21_view_invoice_line.invoice_line_uid
		,COALESCE(product_group.product_group_desc, 'N/A') AS product_group_desc
		,rw.incentive_rewards
		,rw.coop_rewards
		,CASE WHEN 
		p21_view_invoice_line.invoice_line_uid IN (SELECT invoice_line_uid FROM p21_view_vendor_rebate 
			WHERE p21_view_vendor_rebate.row_status_flag = 704) 
		THEN 'Y'
		ELSE 'N'
	END AS rebate_flag
		,CASE
		
		WHEN p21_view_invoice_line.qty_shipped IS NULL THEN p21_view_invoice_line.unit_price 
		WHEN ROUND(COALESCE(rw.incentive_rewards, 0.0000), 4) = 0.0000 THEN p21_view_invoice_line.unit_price
		
		
		ELSE ROUND(p21_view_invoice_line.unit_price - (rw.incentive_rewards / 
			(p21_view_invoice_line.qty_shipped / p21_view_invoice_line.pricing_unit_size)), 2)
	END AS unit_price
		,pricing.sales_price_home
		,pricing.line_other_cost_home
		,pricing.sales_price_home - pricing.line_other_cost_home AS gross_profit_dollars
		,COALESCE(p21_view_invoice_line.pricing_unit_size,oe_line.pricing_unit_size, 1) AS pricing_unit_size
		,oe_line.manual_price_overide
		,CASE COALESCE(rw.oe_incentive_rewards,0)
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS oe_line_rewards_flag
		,COALESCE(p21_view_invoice_line.cost_price_page_uid, oe_line.cost_price_page_uid, oe_line.price_page_uid) AS cost_price_page_uid
		,CASE 
		WHEN COALESCE(oe_line.manual_price_overide, 'N') = 'Y' THEN 'Manual Override'
		ELSE CASE 
			WHEN COALESCE(p21_view_invoice_line.job_price_line_uid, 0) = 0 THEN CASE
					WHEN price_page.description IS NULL THEN 'Unknown'
					ELSE price_page.description
				END
			ELSE 'Contract'
		END 		
	END AS pricing_method
		,COALESCE(oe_line_source_loc.location_name, 'None') AS source_location_name
		,COALESCE(location.location_name, 'None') AS sales_location_name
		,COALESCE(oe_line_ship_loc.location_name, 'None') AS ship_location_name
		,COALESCE(inv_mast.class_id1, 'N/A') AS item_class1
		,COALESCE(inv_mast.class_id2, 'N/A') AS item_class2
		,inv_mast.extended_desc
		,inv_mast.base_unit
		,COALESCE(pf.price_family_id,'') AS price_family_id
		,COALESCE(pf.price_family_desc,'') AS price_family_desc
		,COALESCE(invoice_line_ud.updated_salesrep_id, oe_line_ud.updated_salesrep_id, oe_line_ud.oe_salesrep_id, 0) AS salesrep_id
		,CASE WHEN LEN(RTRIM(LTRIM(ISNULL(salesrep_contact_ud.nickname,'')))) > 0 THEN salesrep_contact_ud.nickname ELSE salesrep_contact.first_name END + ' ' + salesrep_contact.last_name AS salesrep_name
		,COALESCE(manager_contact.id, '0') AS manager_id
		,COALESCE(sales_mgr.sales_manager_names, 'None') AS manager_name
		,dbo.kb_fn_get_product_manager(p21_view_invoice_line.inv_mast_uid) AS product_manager_id

	FROM	invoice_hdr  WITH (NOLOCK)
	INNER JOIN p21_view_invoice_line  WITH (NOLOCK)
		ON (invoice_hdr.invoice_no = p21_view_invoice_line.invoice_no)
	-- these INNER JOINs decide which rows exist in the kb_ view, so they stay even where no column is read
	INNER JOIN company  WITH (NOLOCK)
		ON (invoice_hdr.company_no = company.company_id)
	INNER JOIN customer WITH (NOLOCK)
		ON (invoice_hdr.sold_to_customer_id = customer.customer_id)
		AND (invoice_hdr.company_no = customer.company_id)
	INNER JOIN currency_hdr  WITH (NOLOCK)
		ON currency_hdr.currency_id = customer.currency_id
	-- primary salesrep only: invoice_hdr_salesrep has one row per rep (split commissions)
	INNER JOIN invoice_hdr_salesrep  WITH (NOLOCK)
		ON invoice_hdr_salesrep.invoice_number = invoice_hdr.invoice_no
		AND invoice_hdr_salesrep.primary_salesrep = 'Y'
	LEFT OUTER JOIN oe_hdr  WITH (NOLOCK)
		ON invoice_hdr.order_no = oe_hdr.order_no
	LEFT OUTER JOIN oe_hdr_advance_billing  WITH (NOLOCK)
		ON oe_hdr_advance_billing.order_no = invoice_hdr.order_no
	LEFT OUTER JOIN inv_loc  WITH (NOLOCK)
		ON p21_view_invoice_line.inv_mast_uid = inv_loc.inv_mast_uid
		AND invoice_hdr.sales_location_id = inv_loc.location_id
		AND invoice_hdr.company_no = inv_loc.company_id
	LEFT OUTER JOIN oe_line  WITH (NOLOCK)
		ON (p21_view_invoice_line.oe_line_number = oe_line.line_no)
		AND (p21_view_invoice_line.order_no = oe_line.order_no)
		-- 12.8 ZFG 10/04/11 - Scopus 1000981: Do not join to oe_line for service labor invoice records.
		AND (p21_view_invoice_line.invoice_line_type <> 1577)
	LEFT OUTER JOIN location  WITH (NOLOCK)
		ON (COALESCE(invoice_hdr.sales_location_id, oe_hdr.location_id, 0) = location.location_id)
	LEFT OUTER JOIN location AS oe_line_source_loc  WITH (NOLOCK)
		ON (oe_line.source_loc_id = oe_line_source_loc.location_id)
	LEFT OUTER JOIN location AS oe_line_ship_loc  WITH (NOLOCK)
		ON (oe_line.ship_loc_id = oe_line_ship_loc.location_id)
	LEFT OUTER JOIN inv_mast  WITH (NOLOCK)
		ON (p21_view_invoice_line.inv_mast_uid = inv_mast.inv_mast_uid)
	LEFT OUTER JOIN price_page WITH (NOLOCK)
		ON price_page.price_page_uid = COALESCE(p21_view_invoice_line.cost_price_page_uid, oe_line.cost_price_page_uid, oe_line.price_page_uid)
	LEFT JOIN customer_ud WITH(NOLOCK)
		ON customer_ud.company_id = invoice_hdr.company_no
		AND customer_ud.customer_id = invoice_hdr.sold_to_customer_id
	LEFT JOIN oe_line_ud WITH(NOLOCK)
		ON oe_line_ud.line_no = p21_view_invoice_line.oe_line_number
		AND oe_line_ud.order_no = p21_view_invoice_line.order_no
	LEFT JOIN invoice_line_ud WITH(NOLOCK)
		ON invoice_hdr.invoice_no = invoice_line_ud.invoice_no
		AND p21_view_invoice_line.line_no = invoice_line_ud.line_no
	-- Salesrep: invoice-line override, else order-line override, else order-line rep
	LEFT JOIN contacts AS salesrep_contact WITH(NOLOCK)
		ON salesrep_contact.id = CONVERT(VARCHAR(16), COALESCE(invoice_line_ud.updated_salesrep_id,
			oe_line_ud.updated_salesrep_id,
			oe_line_ud.oe_salesrep_id,
			0))
	LEFT JOIN contacts_ud AS salesrep_contact_ud WITH(NOLOCK)
		ON salesrep_contact.id = salesrep_contact_ud.id
-- Sales manager (was kb_fn_get_sales_manager inside this JOIN predicate + kb_fn_get_sales_manager_names in the SELECT)
OUTER APPLY dbo.asi_fnt_get_sales_manager(salesrep_contact.id, inv_mast.commission_class_id) AS sales_mgr
LEFT JOIN contacts AS manager_contact WITH(NOLOCK)
	ON manager_contact.id = sales_mgr.sales_manager_id
-- Rewards (was LEFT JOIN kb_view_invoice_line_rewards -- that view aggregated ALL invoice history,
-- including an all-orders inv_counter GROUP BY, before this join could narrow it)
OUTER APPLY (
	SELECT
		SUM(COALESCE(rpv.accumulated_coop_dollars, 0)) AS coop_rewards
		-- auto incentive points from the invoice, plus the potentially split incentive points from order entry
		,SUM(COALESCE(rpv.accumulated_incentive_points, 0))
			+ MAX(CASE
				-- Joe: RMA returns on Funds -- use the invoice_line_ud updated fund value
				WHEN inv_counter.invoice_count IS NULL THEN COALESCE(this_line.ilu_extended_reward, this_line.olu_extended_reward, 0)
				ELSE CASE WHEN this_line.ilu_extended_reward IS NOT NULL THEN this_line.ilu_extended_reward
					ELSE COALESCE(this_line.olu_extended_reward, 0) * (this_line.qty_shipped / inv_counter.qty_ordered)
				END
			END) AS incentive_rewards
		,SUM(COALESCE(rpv.accumulated_incentive_points, 0)) AS auto_incentive_rewards
		,MAX(CASE
				WHEN inv_counter.invoice_count IS NULL THEN COALESCE(this_line.ilu_extended_reward, this_line.olu_extended_reward, 0)
				ELSE CASE WHEN this_line.ilu_extended_reward IS NOT NULL THEN this_line.ilu_extended_reward
					ELSE COALESCE(this_line.olu_extended_reward, 0) * (this_line.qty_shipped / inv_counter.qty_ordered)
				END
			END) AS oe_incentive_rewards
	-- outer values projected through a derived table so the aggregates below reference only
	-- local columns (an aggregate mixing outer and inner columns is Msg 8124)
	FROM (SELECT
			p21_view_invoice_line.invoice_line_uid
			,p21_view_invoice_line.order_no
			,p21_view_invoice_line.oe_line_number
			,p21_view_invoice_line.qty_shipped
			,invoice_line_ud.extended_reward AS ilu_extended_reward
			,oe_line_ud.extended_reward AS olu_extended_reward
		) AS this_line
	-- order line split across more than one invoice line: a lifetime property, so a full count --
	-- but only for THIS order line, not every order line in history
	OUTER APPLY (
		SELECT oel.qty_ordered, COUNT(il2.invoice_no) AS invoice_count
		FROM p21_view_oe_line AS oel
		LEFT JOIN p21_view_invoice_line AS il2
			ON il2.order_no = oel.order_no
			AND il2.oe_line_number = oel.line_no
		WHERE oel.order_no = this_line.order_no
			AND oel.line_no = this_line.oe_line_number
		GROUP BY oel.order_no, oel.line_no, oel.qty_ordered
		HAVING COUNT(il2.invoice_no) > 1
	) AS inv_counter
	LEFT JOIN p21_view_rewards_program_values AS rpv
		ON rpv.invoice_line_uid = this_line.invoice_line_uid
		AND rpv.row_status_flag = 704
	WHERE
		(COALESCE(rpv.accumulated_coop_dollars, 0) <> 0
		OR COALESCE(rpv.accumulated_incentive_points, 0) 
			+ CASE
				WHEN inv_counter.invoice_count IS NULL THEN COALESCE(this_line.ilu_extended_reward, this_line.olu_extended_reward, 0)
				ELSE COALESCE(this_line.ilu_extended_reward, this_line.olu_extended_reward, 0) * (this_line.qty_shipped / inv_counter.qty_ordered)
			END <> 0)
	-- the kb_ view only had a row when the filter above kept one (otherwise its LEFT JOIN gave NULLs)
	HAVING COUNT(*) > 0
) AS rw
-- Direct shipments incl. rebills (was kb_view_direct_invoices_incl_rebills -> kb_view_oe_pick_ticket + kb_view_rebill_invoices).
-- Same logic: a direct, non-deleted pick ticket flags its invoice -- or, when that invoice was rebilled,
-- every invoice in the rebill chain instead. kb_view_oe_pick_ticket was only oe_pick_ticket + CONVERT(VARCHAR(10), invoice_no).
LEFT JOIN (
	SELECT DISTINCT CONVERT(VARCHAR(10), CASE WHEN rebill.invoice_no IS NULL THEN CONVERT(VARCHAR(10), pt.invoice_no)
		ELSE rebill.invoice_no END) AS invoice_no
	FROM oe_pick_ticket AS pt WITH (NOLOCK)
	LEFT JOIN dbo.asi_view_rebill_invoices AS rebill
		ON CONVERT(VARCHAR(10), pt.invoice_no) = rebill.original_invoice_no
	WHERE pt.direct_shipment = 'Y'
		AND pt.delete_flag = 'N'
) AS direct
	ON direct.invoice_no = invoice_hdr.invoice_no
-- Cost overrides for invoices imported from Dancik (2014-10 .. 2017-07, 17,624 lines).
-- Static copy of the js_view_open_invoice_costs TABLE -- see CREATE-TABLE-asi_table_dancik_open_invoice_costs.sql
LEFT JOIN dbo.asi_table_dancik_open_invoice_costs AS open_inv_cost WITH (NOLOCK)
	ON open_inv_cost.invoice_no = invoice_hdr.invoice_no
	AND open_inv_cost.line_no = p21_view_invoice_line.line_no
LEFT JOIN p21_view_price_family AS pf
	ON pf.price_family_uid = inv_mast.default_price_family_uid
-- location 100 product group fallback
LEFT JOIN inv_loc AS inv_loc100 WITH (NOLOCK)
	ON inv_loc100.location_id = 100 AND inv_loc100.company_id = invoice_hdr.company_no
	AND	inv_loc100.inv_mast_uid = p21_view_invoice_line.inv_mast_uid
LEFT JOIN product_group  WITH (NOLOCK)
	ON p21_view_invoice_line.company_id = product_group.company_id
	AND COALESCE(
			CASE inv_loc.product_group_id WHEN '' THEN NULL ELSE inv_loc.product_group_id END,
			CASE inv_loc100.product_group_id WHEN '' THEN NULL ELSE inv_loc100.product_group_id END
		) = product_group.product_group_id
-- Service-order child-line sums (was an all-history GROUP BY derived table). Every column that reads
-- drv_sumlines sits inside a pricing_option = 0 AND order_type = 1706 branch, so skip the seek otherwise.
OUTER APPLY (
	SELECT
		SUM(invoice_line.cogs_amount_home) AS sum_cogs_home
		,SUM(invoice_line.extended_price_home) AS sum_price_home
		,SUM(CASE invoice_line.invoice_line_type
			WHEN 1577 THEN invoice_line.other_cost_home * invoice_line.hours_worked
			WHEN 1719 THEN invoice_line.other_cost_home * invoice_line.qty_shipped
		END) AS sum_other_cost_home
	FROM p21_view_invoice_line AS invoice_line
	INNER JOIN invoice_hdr AS sum_ih WITH (NOLOCK)
		ON sum_ih.invoice_no = invoice_line.invoice_no
	WHERE invoice_line.invoice_line_uid_parent = p21_view_invoice_line.invoice_line_uid
		-- invoice line type is a Part or Labor (respectively)
		AND invoice_line.invoice_line_type IN (1719, 1577)
		AND COALESCE(oe_line.pricing_option, 0) = 0
		AND oe_hdr.order_type = 1706
) AS drv_sumlines
-- sales_price_home / line_other_cost_home, computed once (gross_profit_dollars = their difference)
CROSS APPLY (
	SELECT
		-- Sales Price Home Calculation, adjusted for incentive rewards
		(CASE COALESCE(oe_hdr_advance_billing.advance_bill, 'N')
		WHEN 'Y' THEN ((p21_view_invoice_line.QTY_SHIPPED * (p21_view_invoice_line.UNIT_PRICE_home/
			COALESCE(p21_view_invoice_line.pricing_unit_size,1))) - COALESCE(rw.incentive_rewards, 0))
		WHEN 'N' THEN	   	
			CASE COALESCE (oe_line.pricing_option,0)			 		
				-- pricing by component
				WHEN 1 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent	
						WHEN 0 THEN 0 
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(rw.incentive_rewards, 0) 
					END)
				-- pricing by assembly using component prices
				WHEN 2 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(rw.incentive_rewards, 0) 
						ELSE 0 
					END)
				-- pricing by assembly
				WHEN 3 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(rw.incentive_rewards, 0) 
						ELSE 0 
					END)
				-- 4s have a zero for extended price for whatever reason
				WHEN 4 THEN  0 
				-- most of our orders (not assembly/component)
				WHEN 0 THEN ( 
					CASE oe_hdr.order_type 
						WHEN 1706 THEN (
							CASE 
								WHEN p21_view_invoice_line.invoice_line_type = 0 THEN drv_sumlines.sum_price_home - COALESCE(rw.incentive_rewards, 0) -- + COALESCE(drv_sumtaxes.sum_taxes,0)
								ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(rw.incentive_rewards, 0)	
							END)
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(rw.incentive_rewards, 0)
					END )	
				ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(rw.incentive_rewards, 0)
			END
	END) AS sales_price_home

		-- Line_other_cost_home calculation, ** NOT ADJUSTED FOR CO-OP ** but adjusted for imported open invoices with bad costs
		,CASE COALESCE (oe_line.pricing_option, 0)
		WHEN 1 THEN ( 
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN 0 
				ELSE (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) 
			END)
		WHEN 2 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) 
				ELSE 0 
			END)
		WHEN 3 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) 
				ELSE 0 
			END)
		-- kb added when 
		WHEN 4 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) 
				ELSE 0 
			END)
		--WHEN 1 THEN (
		--	CASE p21_view_invoice_line.invoice_line_uid_parent
		--		WHEN 0 THEN 0 
		--		ELSE (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home) 
		--			* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
		--	END)
		WHEN 0 THEN  (
			CASE WHEN oe_hdr.order_type = 1706 THEN (
				CASE p21_view_invoice_line.invoice_line_type
					WHEN 1577 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
						* p21_view_invoice_line.hours_worked) 
					WHEN 1719 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
						* p21_view_invoice_line.qty_shipped) 
					ELSE drv_sumlines.sum_other_cost_home 
				END)
			ELSE (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
				* p21_view_invoice_line.qty_shipped) 
		END)
		ELSE 	(COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
			* p21_view_invoice_line.qty_shipped) 
	END AS line_other_cost_home
) AS pricing

	WHERE
	-- Only show approved invoices	
	invoice_hdr.approved = 'Y'
	
	-- 2 FIXES FOR IMPORTED HISTORICAL SALES DATA
	AND (
		-- invoice was not imported
		ISNULL(invoice_hdr.source_type_cd,0) <> 1661
		-- or invoice is not for one of the imported poorly items
		OR p21_view_invoice_line.item_id NOT IN (
			-- All Tile / Dancik poor items
			'DELIVERY', 'DISC', 'FUEL CHG', 'FUND', 'HAND', 'MISC', 'OVERPAYMENT', 'INBOUND FUEL SURCHARGE',
			-- CCS / Solar poor items
			'BALANCING_ITEM','FREIGHT_ITEM','HANDLING_ITEM')
	)
	AND (
		-- invoice was imported 
		ISNULL(invoice_hdr.source_type_cd,0) = 1661
		-- or invoice class is not z (zero dollar invoices)
		OR	invoice_hdr.invoice_class NOT IN ('Z')
	)
	
	-- Omit invoices that are categorized as finance charges
	AND	invoice_hdr.invoice_class NOT IN ('FINANCE')

	-- Omit freight and other charges
	AND p21_view_invoice_line.item_id <> 'FRT OUT'
	AND COALESCE(product_group.product_group_id,'') NOT IN ('OCI', 'OCHARGE')
	AND p21_view_invoice_line.inv_mast_uid <> 0 -- from bad imported items

	
	-- Omit invoices that are categorized as:
	-- 'B' = installment Debit 
	-- 'T' = installment Credit 
	-- 'X' = installment cancelation
	-- 'R' = Bad Debt Recovery
	-- 'W' = Bad Debt Write-off
	-- 'A' = Tax Adjustment 
	-- 'P' = Downpayment invoice
	-- 'Z' = ???
	-- 'Y' = ???
	-- Includes: 'I' = original invoice; 'C' = Credit memo; 'D' = Debit memo; 'M' = Mfg Rep Invoices / Commissions resulting from MRO orders
	AND	invoice_hdr.invoice_adjustment_type NOT IN ('B', 'T', 'X', 'R', 'W', 'A', 'P', 'Z', 'Y')

	-- Omit consolidated invoices
	AND	invoice_hdr.consolidated <> 'C'
	
	-- Omit invoice line items that are tax jurisdictions.
	-- The tax_item flag indicates whether the item is a tax jurisdiction or an actual line item on the invoice. 
	-- It does NOT indicate if the item is taxable.
	AND	p21_view_invoice_line.tax_item = 'N'

	-- Omit invoices generated from T= intercompany transfer
	-- (O= sales order; N= none, manual invoice or memo)
	AND	invoice_hdr.original_document_type <> 'T'

	-- Omit incoming freight (928), outgoing freight (929), tax (930), ???? (3)
	AND p21_view_invoice_line.invoice_line_type NOT IN (928, 929, 930, 3)		

	-- Omit downpayments, prepayments, and advance bill amounts
	AND	p21_view_invoice_line.item_id NOT IN ('DOWNPAYMENT','PREPAYMENT','cash deposit')
	AND p21_view_invoice_line.item_id <> 'ADVANCE BILL AMOUNT'
	
	-- (primary_salesrep = 'Y' is enforced by the INNER JOIN to invoice_hdr_salesrep above --
	--  the original LEFT JOIN + WHERE primary_salesrep = 'Y' was an inner join in disguise)
	
	-- Determine which invoice lines to include/omit
	AND (
		-- Include invoice lines where there is a nonzero quantity shipped
		p21_view_invoice_line.qty_shipped > 0.0000
		OR p21_view_invoice_line.qty_shipped < 0.0000
		-- Include service order invoice lines...
		OR (p21_view_invoice_line.invoice_line_type = 1577 
			-- ...only when hours_worked or extended_price are not zero
			AND (COALESCE(p21_view_invoice_line.hours_worked, 0) <> 0 
				OR p21_view_invoice_line.extended_price <> 0
			)
		)
	)
 
	AND ( 
		-- Include order lines that are not lot billed
		(COALESCE(oe_line.lot_bill,'N') = 'N')
		-- Include order lines that are lot billed and...
		OR (oe_line.lot_bill = 'Y'
			-- ... are the parent line and are the 4 = Lot Bill Header
			AND p21_view_invoice_line.invoice_line_uid_parent = 0
			AND p21_view_invoice_line.invoice_line_type = 4
		)
	)
		-- the report's date range, applied here so every lookup above only sees these rows
		AND invoice_hdr.invoice_date BETWEEN @d_start AND @d_end
)
GO

GRANT SELECT ON dbo.asi_fnt_invoice_detail TO p21_application_role
GO
GRANT SELECT ON dbo.asi_fnt_invoice_detail TO PxxiUser
GO
