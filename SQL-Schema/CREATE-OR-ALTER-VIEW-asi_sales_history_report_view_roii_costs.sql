USE [P21Play]
GO

/*
=====================================================================================================
 dbo.asi_sales_history_report_view_roii_costs
 Replacement for dbo.kb_sales_history_report_view_roii_costs (KB, last modified 2023-01-01).
 Known consumers (all read it as `shrv`): SSRS "Invoice Detail" (Company Reports/Sales),
 "Buying Group Invoice Detail", "InvoiceDetail with Live Standard Cost".

 DROP-IN CONTRACT: same column names, same column order, same rows as the kb_ view.
 Prove it with Sql-Scripts\Sales\roii-costs-asi\02-verify-equivalence-and-perf.sql before any
 consumer is repointed. Do not reorder the SELECT list.

 Deploy order: asi_fnt_get_sales_manager -> asi_view_rebill_invoices
               -> asi_table_dancik_open_invoice_costs -> this view.

 What changed vs the kb_ original (2026-10-02, Mark Goldyn):
   1. 2 non-inlineable scalar UDFs -> inline TVF (set-based, expanded into the plan, no row-by-row calls)
        kb_fn_get_sales_manager  (was inside a JOIN predicate)    -> asi_fnt_get_sales_manager.sales_manager_id
        kb_fn_get_sales_manager_names (+ nested kb_fn_get_contact_name) -> asi_fnt_get_sales_manager.sales_manager_names
   2. Full-history aggregates -> correlated OUTER APPLY, so they only touch rows the caller's
      invoice_date filter keeps (same lesson as SA-55014: unfiltered aggregates were the cost)
        kb_view_invoice_line_rewards (incl. its all-orders inv_counter GROUP BY) -> rw
        drv_sumlines  -> evaluated only for service orders (order_type 1706, pricing_option 0), the
                         only branches that read it; dropped its unused commission sums and the
                         oe_hdr join that only fed them
        invoice_line_summary -> per-invoice COUNT
   3. Dead joins removed (no column referenced anywhere): shipping_route, inv_sales_loc,
      job_price_line/job_price_hdr (the unaliased pair; _a/_b kept), progress_billing_x_invoice_hdr,
      oe_line_dealer_commission, system_setting_Gallon, item_uom_gallon, order_floor_plan_xref_10002,
      drv_nested_lot_header_comm_cost, salesrep_ud (duplicate of salesrep_contact_ud),
      address_history (INNER JOIN, no column used -- the verify script checks it never dropped a row)
   4. invoice_hdr_salesrep LEFT JOIN + WHERE primary_salesrep = 'Y' -> plain INNER JOIN (same rows)
   5. sales_price_home / line_other_cost_home computed once (pricing CROSS APPLY);
      gross_profit_dollars = their difference instead of repeating both 40-line CASEs.

 Also replaced (2026-10-02, after the Play dependency pull):
   - kb_view_direct_invoices_incl_rebills -> oe_pick_ticket + dbo.asi_view_rebill_invoices (verbatim port)
   - js_view_open_invoice_costs (a static TABLE of Dancik-era costs) -> dbo.asi_table_dancik_open_invoice_costs (copy)

 STILL kb_ (data, not logic):
   - kb_table_sales_manager_values / _all, read inside asi_fnt_get_sales_manager
   - kb_fn_get_product_manager -- KEPT ON PURPOSE until the P21 "Product Manager" role + users_ud
     product assignments have good values (its hard-coded mapping still names departed GTHOMAS / KBENISH).
     Inlineable on SQL 2019, so it isn't a row-by-row cost.
=====================================================================================================
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[asi_sales_history_report_view_roii_costs]
AS
/* NOTES (carried over from the kb_ original):
	From the original view, these fields were omitted (and why):
		sales_price (there's a _home version)
		assembly_sales_price (there's a _home version)
		extended_price (is always null for some reason)
		shipping_cost (irrelevant for sales reports because it's a total for the invoice header and appears on all lines)
		cogs_amount (there's a _home version)
		line_commission_cost (there's a _home version)
		line_commission_cost_home (this will not be used at invoice in favor of the more accurate "other cost")
		line_other_cost (there's a _home version)
		assembly_commission_cost (there's a _home version)
		assembly_other_cost (there's a _home version)
		assembly_cogs_amount (there's a _home version)
		other_charge_line_price (there's a _home version)
		other_other_charge_cost_home (is always zero)
		other_charge_cost_home (is always zero)
		commission_other_charge_cost_h (is always zero)
		other_charge_cost (is always zero)
		commission_other_charge_cost (is always zero)
		other_other_charge_cost (is always zero)
		sum_other_cost (is always NULL)
		sum_other_cost_home (is always NULL)
		assembly_sales_price_home (not using assemblies)
		assembly_commission_cost_home (not using assemblies)
		assembly_other_cost_home (not using assemblies)
		assembly_cogs_amt_home (not using assemblies)

	From the original view, these fields were changed (and how):
		sales_cost (renamed to gross_moving_avg_unit_cost NOTE: can sometimes be NULL)
		commission_cost (renamed to gross_commission_cost because it takes rebates into account but not coop rewards)
		other_cost (renamed to net_unit_other_cost because it's the price page cost less the rebate)
		line_commission_cost_home (renamed to net_ext_commission_cost because it's the extended MAC less the rebate)
		cogs_amount_home (renamed to gross_inventory_cost)
		gross_profit_dollars added (sales_price_home minus line_other_cost_home)

	pricing_option comes up a lot.  This is what it means:
		1, "By Component", 
		2, "By Assembly Using Component Prices", 
		3, "By Assembly", 
		else, "N/A"
	
	Product Group ID as assigned on the invoice line or order line (inside Coalesce)
		(CASE p21_view_invoice_line.product_group_id
			WHEN '' THEN NULL
			ELSE p21_view_invoice_line.product_group_id
		END),
		(CASE oe_line.product_group_id
			WHEN '' THEN NULL
			ELSE oe_line.product_group_id
		END),
*/
SELECT	
	/* 
	 *	Invoice Header
	 */
	invoice_hdr.company_no AS company_id
	,company.company_name
	,COALESCE(branch.branch_description, 'None') AS branch_description
	,invoice_hdr.invoice_date
	,invoice_hdr.invoice_no
	,invoice_hdr.order_no
	,invoice_hdr.sold_to_customer_id AS customer_id
	,address.corp_address_id
	,corp_addr.name AS corp_name
	,customer.customer_name
	,customer_ud.dba_name
	,ISNULL(customer_ud.chain,'(None)') AS chain
	,invoice_hdr.ship_to_id
	,invoice_hdr.ship2_name
	,invoice_hdr.po_no
	,invoice_hdr.brokerage
	,invoice_hdr.freight
	,invoice_hdr.period
	,invoice_hdr.year_for_period
	,invoice_hdr.invoice_type
	,invoice_hdr.ship_date
	,invoice_hdr.amount_paid
	,invoice_hdr.paid_in_full_flag AS paid_in_full
	,invoice_hdr.bill2_country
	,invoice_hdr.ship2_country
	,invoice_hdr.bad_debt_amount
	,invoice_hdr.invoice_class
	,invoice_hdr.terms_id
	,COALESCE(invoice_hdr.branch_id, 'None') branch_id
	,customer.currency_id
	,invoice_hdr.invoice_adjustment_type
	,invoice_hdr.total_amount AS total_sales
	,invoice_hdr.tax_amount
	,invoice_hdr.other_charge_amount
	,COALESCE(invoice_hdr.sales_location_id, oe_hdr.location_id, 0) AS sales_location_id
	,CAST(CAST(invoice_hdr.year_for_period AS CHAR(4)) + RIGHT('00' + CAST(invoice_hdr.period AS VARCHAR(2)), 2) AS INTEGER) AS year_and_period
	,invoice_hdr.inv_no_display
	,invoice_hdr.ar_account_no
	,invoice_hdr.gl_freight_account_no
	,invoice_hdr.job_id
	,invoice_hdr.record_type_cd
	,COALESCE(invoice_hdr.source_type_cd, 0) AS source_type_cd
	,CASE WHEN COALESCE(invoice_hdr.record_type_cd, 0) = 2594
		THEN 'Y'
		ELSE 'N'
	END AS 'rebilled_flag'
	,invoice_hdr.date_created
	,CASE WHEN direct.invoice_no IS NULL THEN 'N' ELSE 'Y' END AS direct_flag

	/* 
	 *	Order Header
	 */
	,oe_hdr.order_date
	,oe_hdr.contact_id
	,COALESCE(oe_hdr.rma_flag, 'N') AS rma_flag
	,CASE WHEN 
		oe_line.oe_line_uid IN (SELECT rma_linked_oe_line_uid FROM p21_view_oe_line_rma 
			WHERE p21_view_oe_line_rma.row_status_flag = 704) 
		THEN 'Y'
		ELSE 'N'
	END AS linked_to_rma
	,COALESCE(oe_hdr.taker, 'N/A') AS taker
	,COALESCE(oe_hdr.job_name,'') AS job_name
	,COALESCE(oe_hdr.projected_order, 'N') AS projected_order
	,COALESCE(oe_hdr_advance_billing.advance_bill, 'N') AS advance_bill
	,oe_hdr.source_code_no
	,order_source.code_description AS order_source
	,COALESCE(oe_hdr.order_type, 706) AS order_type
	,oe_hdr_mfr.vendor_id AS mfr_vendor_id
	,prod_order_hdr.prod_order_number
	,prod_order_hdr.order_date AS prod_order_date
	,COALESCE(oe_hdr_progress_billing.progress_bill_flag,'N') AS progress_bill_flag
	,oe_hdr_progress_billing.percent_billed
	
	/* 
	 *	Invoice Line
	 */
	,COALESCE(invoice_line_summary.counter, 0) AS number_of_invoice_lines 
	,p21_view_invoice_line.qty_shipped
	,p21_view_invoice_line.unit_of_measure   
	,COALESCE(inv_mast.item_id,p21_view_invoice_line.item_id) AS item_id
	,p21_view_invoice_line.item_desc
	,COALESCE(p21_view_invoice_line.inv_mast_uid, 0) AS inv_mast_uid
	,COALESCE(p21_view_invoice_line.supplier_id, oe_line.supplier_id, inv_loc.primary_supplier_id, 0) AS supplier_id
	,p21_view_invoice_line.customer_part_number
	,p21_view_invoice_line.tax_item
	,p21_view_invoice_line.line_no
	,p21_view_invoice_line.oe_line_number
	,p21_view_invoice_line.other_charge_item
	,p21_view_invoice_line.pricing_unit
	,p21_view_invoice_line.invoice_line_uid
	,p21_view_invoice_line.invoice_line_uid_parent
	,p21_view_invoice_line.invoice_line_type
	,p21_view_invoice_line.gl_revenue_account_no
	,p21_view_invoice_line.gl_salse_tax_account_no
	,p21_view_invoice_line.gl_cogs
	,p21_view_invoice_line.gl_inventory
	-- Product Group ID & Description
	,COALESCE(product_group.product_group_id,'N/A') AS product_group_id
	,COALESCE(product_group.product_group_desc, 'N/A') AS product_group_desc
	-- Supplier Name (as on the invoice or order line)
	,CASE
		WHEN p21_view_invoice_line.supplier_id IS NOT NULL THEN supplier_invoice.supplier_name
		WHEN oe_line.supplier_id IS NOT NULL THEN supplier_oe.supplier_name
		WHEN inv_loc.primary_supplier_id IS NOT NULL THEN supplier_inv_loc.supplier_name
		ELSE 'N/A'
	END AS supplier_name
	,rw.incentive_rewards
	,rw.coop_rewards
	,CASE WHEN 
		p21_view_invoice_line.invoice_line_uid IN (SELECT invoice_line_uid FROM p21_view_vendor_rebate 
			WHERE p21_view_vendor_rebate.row_status_flag = 704) 
		THEN 'Y'
		ELSE 'N'
	END AS rebate_flag
/***
 *** Adjusted unit price by incentive points reward amount 
 ***/
	,p21_view_invoice_line.unit_price AS inflated_unit_price
	,CASE
		-- Ignore this adjustment when there is no quantity shipped or extended reward on the order line
		WHEN p21_view_invoice_line.qty_shipped IS NULL THEN p21_view_invoice_line.unit_price 
		WHEN ROUND(COALESCE(rw.incentive_rewards, 0.0000), 4) = 0.0000 THEN p21_view_invoice_line.unit_price
		-- Adjust unit price by removing reward (reward is already divided in this view, if many invoice lines to one order line)
		-- Divide reward by quantity purchased, since reward is a total for the line
		ELSE ROUND(p21_view_invoice_line.unit_price - (rw.incentive_rewards / 
			(p21_view_invoice_line.qty_shipped / p21_view_invoice_line.pricing_unit_size)), 2)
	END AS unit_price
	-- Inflated Sales Price Home Calculation
	,(CASE COALESCE(oe_hdr_advance_billing.advance_bill, 'N')
		WHEN 'Y' THEN ((p21_view_invoice_line.QTY_SHIPPED * (p21_view_invoice_line.UNIT_PRICE_home/
			COALESCE(p21_view_invoice_line.pricing_unit_size,1))))
		WHEN 'N' THEN	   	
			CASE COALESCE (oe_line.pricing_option,0)			 		
				WHEN 1 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent	
						WHEN 0 THEN 0 
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home 
					END)
				WHEN 2 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home 
						ELSE 0 
					END)
				WHEN 3 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home 
						ELSE 0 
					END)
				WHEN 4 THEN  0 
				WHEN 0 THEN ( 
					CASE oe_hdr.order_type 
						WHEN 1706 THEN (
							CASE 
								WHEN p21_view_invoice_line.invoice_line_type = 0 THEN drv_sumlines.sum_price_home -- + COALESCE(drv_sumtaxes.sum_taxes,0)
								ELSE p21_view_invoice_line.EXTENDED_PRICE_home 
							END)
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home 
					END )	
				ELSE p21_view_invoice_line.EXTENDED_PRICE_home 
			END
	END) AS inflated_sales_price_home
/***
 *** Adjusted sales price home by incentive points reward amount
 ***/
	-- Sales Price Home (adjusted for incentive rewards) -- computed once in the pricing CROSS APPLY below
	,pricing.sales_price_home

	-- Deflated_line_other_cost_home calculation
	,CASE COALESCE (oe_line.pricing_option, 0)
		WHEN 1 THEN ( 
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN 0 
				ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) 
			END)
		WHEN 2 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
				ELSE 0 
			END)
		WHEN 3 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
				ELSE 0 
			END)
		-- kb added when
		WHEN 4 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
				ELSE 0 
			END)
		--WHEN 1 THEN (
		--	CASE p21_view_invoice_line.invoice_line_uid_parent
		--		WHEN 0 THEN 0 
		--		ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
		--	END)
		WHEN 0 THEN  (
			CASE WHEN oe_hdr.order_type = 1706 THEN (
				CASE p21_view_invoice_line.invoice_line_type
					WHEN 1577 THEN p21_view_invoice_line.other_cost_home * p21_view_invoice_line.hours_worked
					WHEN 1719 THEN p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped
					ELSE drv_sumlines.sum_other_cost_home
				END)
			ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
		END)
		ELSE 	(p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped)
	END AS deflated_line_other_cost_home

	-- Line_other_cost_home calculation, adjusted for co-op and for imported open invoices with bad costs
	,CASE COALESCE (oe_line.pricing_option, 0)
		WHEN 1 THEN ( 
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN 0 
				ELSE (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
			END)
		WHEN 2 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
				ELSE 0 
			END)
		WHEN 3 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
				ELSE 0 
			END)
		-- kb added when 
		WHEN 4 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
					* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
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
						* p21_view_invoice_line.hours_worked) + COALESCE(rw.coop_rewards, 0)
					WHEN 1719 THEN (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
						* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
					ELSE drv_sumlines.sum_other_cost_home - rw.coop_rewards
				END)
			ELSE (COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
				* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
		END)
		ELSE 	(COALESCE(open_inv_cost.calculated_base_unit_cost, p21_view_invoice_line.other_cost_home)
			* p21_view_invoice_line.qty_shipped) + COALESCE(rw.coop_rewards, 0)
	END AS inflated_line_other_cost_home


	-- Line Other Cost Home, NOT adjusted for co-op -- computed once in the pricing CROSS APPLY below
	,pricing.line_other_cost_home

	-- gross_profit_dollars = sales_price_home - line_other_cost_home (the original repeated both 40-line CASEs inline here)
	,pricing.sales_price_home - pricing.line_other_cost_home AS gross_profit_dollars

	-- COGs Amount Home Calculation
	,CASE COALESCE (oe_line.pricing_option, 0)
		WHEN 1 THEN ( 
			CASE p21_view_invoice_line.invoice_line_uid_parent 
				WHEN 0 THEN 0 
				ELSE p21_view_invoice_line.cogs_amount_home 
			END)
		WHEN 2 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent 
				WHEN 0 THEN p21_view_invoice_line.cogs_amount_home 
				ELSE 0 
			END)
		WHEN 3 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent 
				WHEN 0 THEN p21_view_invoice_line.cogs_amount_home 
				ELSE 0 
			END)
		WHEN 0 THEN ( 
			CASE oe_hdr.order_type 
				WHEN 1706 THEN (
					CASE 
						WHEN p21_view_invoice_line.invoice_line_type = 0 THEN drv_sumlines.sum_cogs_home
						ELSE p21_view_invoice_line.cogs_amount_home 	
					END)
				ELSE p21_view_invoice_line.cogs_amount_home
			END )
		ELSE p21_view_invoice_line.cogs_amount_home 
	END AS gross_inventory_cost_home -- cogs_amount_home

	-- Other Charge Line Price Home Calculation
	-- Shouldn't have rewards, but I threw them in just in case.
	,CASE  p21_view_invoice_line.other_charge_item 	
		WHEN 'Y' THEN 					
			CASE COALESCE (oe_line.pricing_option,0)
				WHEN 1 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN 0.0000 
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(rw.incentive_rewards, 0)
					END)
				WHEN 2 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(rw.incentive_rewards, 0)
						ELSE 0.0000 
					END)
				WHEN 3 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(rw.incentive_rewards, 0) 
						ELSE 0.0000 
					END)
				WHEN 4 THEN  0.0000 
				ELSE 	p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(rw.incentive_rewards, 0)
			END 
		WHEN 'N' THEN  0.0000
	END AS other_charge_line_price_home

	,(p21_view_invoice_line.commission_cost * COALESCE(p21_view_invoice_line.sales_unit_size, 1)) AS gross_unit_commission_cost -- net_moving_avg_unit_cost -- commission_cost
	,(p21_view_invoice_line.other_cost * COALESCE(p21_view_invoice_line.sales_unit_size, 1)) AS deflated_unit_other_cost -- other_cost 
	,(p21_view_invoice_line.commission_cost * p21_view_invoice_line.qty_shipped) AS gross_line_commission_cost -- net_moving_avg_unit_cost -- commission_cost
	,(p21_view_invoice_line.other_cost * p21_view_invoice_line.qty_shipped) AS deflated_line_other_cost -- other_cost 
	-- net_unit_other_cost adjusted for co-op
	,CASE p21_view_invoice_line.qty_shipped WHEN 0 THEN p21_view_invoice_line.other_cost
		ELSE 
		(p21_view_invoice_line.other_cost + 
			(COALESCE(rw.coop_rewards, 0) / p21_view_invoice_line.qty_shipped)
			) * COALESCE(p21_view_invoice_line.sales_unit_size, 1)
	END AS inflated_net_unit_other_cost -- other_cost 
	
	
	-- net_unit_other_cost ** NOT ADJUSTED FOR CO-OP **
	,CASE p21_view_invoice_line.qty_shipped WHEN 0 THEN p21_view_invoice_line.other_cost
		ELSE 
		(p21_view_invoice_line.other_cost ) * COALESCE(p21_view_invoice_line.sales_unit_size, 1)
	END AS net_unit_other_cost -- other_cost  
	
	
	,p21_view_invoice_line.extended_price AS inflated_detail_price
	,p21_view_invoice_line.extended_price - COALESCE(rw.incentive_rewards, 0) AS detail_price
	,p21_view_invoice_line.cogs_amount AS gross_inventory_cost -- detail_cogs
	
	/* 
	 *	Order Line
	 */
	,ISNULL(oe_line.source_loc_id,0) AS source_loc_id
	,ISNULL(oe_line.ship_loc_id,0) AS ship_loc_id
	,COALESCE(p21_view_invoice_line.sales_unit_size, oe_line.unit_size, 1) AS unit_size	
	,COALESCE(oe_line.assembly,  'N') AS oe_line_assembly
	,COALESCE(oe_line.parent_oe_line_uid, 0) AS parent_oe_line_uid
	,COALESCE(oe_line.oe_line_uid, 0) AS oe_line_uid
	,COALESCE(p21_view_invoice_line.pricing_unit_size,oe_line.pricing_unit_size, 1) AS pricing_unit_size
	,oe_line.sales_cost AS gross_moving_avg_unit_cost -- sales_cost
	,oe_line_lot_billing.price_basis --'I' indicates ItemizedLotBilling and 'N' indicates NestedLotBilling
	,oe_line.lot_bill
	,oe_line.detail_type
	--,(COALESCE(oe_line_dealer_commission.dealer_commission_amt,0) * p21_view_invoice_line.qty_shipped / COALESCE(NULLIF(p21_view_invoice_line.pricing_unit_size,0), 1 )) AS dealer_commission_ext_amt
	,oe_line.pricing_option
	,p21_view_invoice_line.job_price_line_uid
	,oe_line.manual_price_overide
	,oe_line.system_calc_unit_price
	,CASE COALESCE(rw.coop_rewards,0) + COALESCE(rw.incentive_rewards,0) 
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS rewards_flag
	,CASE COALESCE(rw.oe_incentive_rewards,0)
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS oe_line_rewards_flag
	,CASE COALESCE(rw.auto_incentive_rewards,0)
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS automatic_incentive_rewards_flag
	,CASE COALESCE(rw.coop_rewards,0) 
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS automatic_coop_rewards_flag
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
	 
	/* 
	 *	Customer Detail
	 */
	,COALESCE(customer.class_1id, 'N/A') AS customer_class1
	,COALESCE(customer.class_2id, 'N/A') AS customer_class2
	,COALESCE(customer.class_3id, 'N/A') AS customer_class3
	,COALESCE(customer.class_4id, 'N/A') AS customer_class4
	,COALESCE(customer.class_5id, 'N/A') AS customer_class5
	,CASE 
		WHEN customer.currency_id <> company.home_currency_id
			THEN 'F'
			ELSE 'H'
	END AS currency_type
	,customer_ud.closed AS customer_closed
	,customer.delete_flag AS customer_deleted
	,customer_ud.employee
	,customer_ud.opt_out_of_faxes
	,customer_ud.opt_out_of_paper_mail
	,customer_ud.opt_out_of_spiffs
	,customer.date_acct_opened
	,customer.sic_code
	,customer.credit_status
	,customer.default_branch_id
	,CASE customer.customer_type_cd
		WHEN 1203 THEN 'Customer'
		WHEN 1204 THEN 'Lead' -- actually called prospect in p21
		ELSE 'N/A'
	END AS customer_or_lead
	,customer.legacy_id
	,customer.sfdc_account_id
	,customer.customer_uid

	/* 
	 *	Order Contact
	 */
	,COALESCE(
		RTRIM(contacts.first_name + CASE WHEN contacts.mi IS NULL THEN '' ELSE ' ' + contacts.mi END + ' ' + contacts.last_name)
		,oe_hdr_ud.order_contact
		, ''
	) AS order_contact
	,COALESCE(contacts.id,'') AS order_contact_id
	
	/* 
	 *	Location
	 */
	,COALESCE(location.location_name,  'None') AS location_name
	,COALESCE(oe_line_source_loc.location_name, 'None') AS source_location_name
	,COALESCE(location.location_name, 'None') AS sales_location_name
	,COALESCE(oe_line_ship_loc.location_name, 'None') AS ship_location_name
	,COALESCE(inv_loc.stockable, 'N') AS stockable

	/* 
	 *	Item Detail
	 */
	,COALESCE(inv_mast.vendor_consigned, 'N') AS vendor_consigned
	,COALESCE(inv_mast.default_selling_unit, 'N/A') default_sales_unit_of_measure
	,COALESCE(item_uom.unit_size, 1) default_sales_unit_size
	-- KB removed 5/18/2020
	--,item_revision.revision_level
	--,COALESCE(inventory_supplier.manufacturing_class_id, primary_inventory_supplier.manufacturing_class_id, 'N/A') AS manufacturing_class_id
	,COALESCE(inventory_supplier.manufacturing_class_id, 'N/A') AS manufacturing_class_id
	,COALESCE(inv_mast.class_id1, 'N/A') AS item_class1
	,COALESCE(item_class1_desc.class_description, 'N/A') AS manufacturer_name
	,COALESCE(inv_mast.class_id2, 'N/A') AS item_class2
	,COALESCE(item_class2_desc.class_description, 'N/A') AS product_line_name
	,COALESCE(inv_mast.class_id3, 'N/A') AS item_class3
	,COALESCE(inv_mast.class_id4, 'N/A') AS item_class4
	,COALESCE(inv_mast.class_id5, 'N/A') AS item_class5
	,inv_mast.price1 AS unit_list_price
	,inv_mast.default_sales_discount_group AS sales_discount_group
	,inv_mast.default_purchase_disc_group AS purchase_discount_group
	,inv_mast.extended_desc
	,inv_mast.base_unit
	,inv_mast.commission_class_id
	,inv_mast.last_pricing_service_date
	,inv_loc.discontinued
	,inv_mast.discontinued_date
	,COALESCE(inv_mast.rolled_item_flag, 'N') AS rolled_item_flag
	,inv_mast_ud.display AS display_pilot_flag
	,inv_mast_ud.updates AS update_pilot_flag
	,inv_mast_ud.specials_list AS specials_list_flag
	,COALESCE(pf.price_family_uid,0) AS price_family_uid
	,COALESCE(pf.price_family_id,'') AS price_family_id
	,COALESCE(pf.price_family_desc,'') AS price_family_desc

	/* 
	 *	Currency Detail
	 */
	,invoice_hdr.currency_line_uid
	,currency_hdr.currency_desc
	,company.home_currency_id
	
	/* 
	 *	Salesrep Detail
	 */
	,oe_line_ud.oe_salesrep_id
	,COALESCE(invoice_line_ud.updated_salesrep_id, oe_line_ud.updated_salesrep_id, oe_line_ud.oe_salesrep_id, 0) AS salesrep_id

	,salesrep_contact.id AS salesrep_id_varchar
	,CASE WHEN LEN(RTRIM(LTRIM(ISNULL(salesrep_contact_ud.nickname,'')))) > 0 THEN salesrep_contact_ud.nickname ELSE salesrep_contact.first_name END + ' ' + salesrep_contact.last_name AS salesrep_name
	,COALESCE(manager_contact.id, '0') AS manager_id
	,COALESCE(sales_mgr.sales_manager_names, 'None') AS manager_name
	-- KEPT ON PURPOSE (2026-10-02): kb_fn_get_product_manager stays until the P21 "Product Manager" role +
	-- users_ud product assignments have good values; then this becomes a lookup against those. Inlineable on SQL 2019 (is_inlineable = 1).
	,dbo.kb_fn_get_product_manager(p21_view_invoice_line.inv_mast_uid) AS product_manager_id
	,COALESCE(job_price_hdr_a.contract_no,job_price_hdr_b.contract_no,'N/A') AS contract_no
	,COALESCE(job_price_hdr_a.consignment_flag,job_price_hdr_b.consignment_flag,'N') AS consignment_flag
	,vendor.vendor_name AS mfr_vendor_name
	,jc_job.job_description
	,CASE WHEN oe_hdr_progress_billing.row_status_flag = 701
		THEN 'Y'
		ELSE 'N' 
	END AS 'finalized'
	,CASE WHEN invoice_hdr.record_type_cd = 2530
		THEN 'Y'
		ELSE 'N'
	END AS final_invoice

FROM	invoice_hdr  WITH (NOLOCK)
/* INNER JOINS */
INNER JOIN p21_view_invoice_line  WITH (NOLOCK)
	ON (invoice_hdr.invoice_no = p21_view_invoice_line.invoice_no)
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
/* LEFT JOINS */
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
LEFT OUTER JOIN branch  WITH (NOLOCK)
	ON (invoice_hdr.company_no = branch.company_id)
	AND (invoice_hdr.branch_id = branch.branch_id)
LEFT OUTER JOIN contacts  WITH (NOLOCK)
	ON (oe_hdr.contact_id = contacts.id)
LEFT JOIN supplier supplier_oe  WITH (NOLOCK)
	ON (oe_line.supplier_id = supplier_oe.supplier_id)
LEFT JOIN supplier supplier_invoice  WITH (NOLOCK)
	ON (p21_view_invoice_line.supplier_id = supplier_invoice.supplier_id)
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
--12.13 YCHEN 10/09/13 - Scopus#1151323: contract from the invoice line's job price line (a), else the price page's contract line (b)
LEFT OUTER JOIN job_price_line job_price_line_a WITH (NOLOCK)
	ON job_price_line_a.job_price_line_uid = p21_view_invoice_line.job_price_line_uid
LEFT OUTER JOIN job_price_hdr job_price_hdr_a WITH (NOLOCK)
	ON job_price_hdr_a.job_price_hdr_uid = job_price_line_a.job_price_hdr_uid
LEFT OUTER JOIN job_price_line job_price_line_b WITH (NOLOCK)
	ON job_price_line_b.job_price_line_uid = price_page.contract_line_uid
LEFT OUTER JOIN job_price_hdr job_price_hdr_b WITH (NOLOCK)
	ON job_price_hdr_b.job_price_hdr_uid = job_price_line_b.job_price_hdr_uid
LEFT OUTER JOIN address  WITH (NOLOCK)
	ON address.id = customer.customer_id
LEFT OUTER JOIN oe_line_lot_billing  WITH (NOLOCK)
	ON oe_line_lot_billing.oe_line_uid = oe_line.oe_line_uid
LEFT JOIN oe_hdr_mfr  WITH (NOLOCK)
	ON oe_hdr_mfr.oe_hdr_uid = oe_hdr.oe_hdr_uid
LEFT JOIN vendor  WITH (NOLOCK)
	ON vendor.vendor_id = oe_hdr_mfr.vendor_id
	AND vendor.company_id = invoice_hdr.company_no
LEFT JOIN jc_job  WITH (NOLOCK)
	ON jc_job.job_id = invoice_hdr.job_id
LEFT JOIN oe_hdr_progress_billing  WITH (NOLOCK)
	ON oe_hdr_progress_billing.order_no = oe_hdr.order_no
	AND oe_hdr_progress_billing.progress_bill_flag = 'Y'
LEFT JOIN prod_order_line_link WITH (NOLOCK)
	ON prod_order_line_link.transaction_uid = oe_line.oe_line_uid
	AND prod_order_line_link.trans_type = 'O'
	AND oe_hdr_progress_billing.progress_bill_flag = 'Y'
LEFT JOIN prod_order_hdr  WITH (NOLOCK)
	ON prod_order_hdr.prod_order_number = prod_order_line_link.prod_order_number
LEFT JOIN item_uom WITH(NOLOCK)
	ON inv_mast.inv_mast_uid = item_uom.inv_mast_uid
	AND inv_mast.default_selling_unit = item_uom.unit_of_measure
--ATG 04/15/2015 - Feature 58270: inventory_supplier for manufacturing_class_id
LEFT JOIN inventory_supplier WITH (NOLOCK)
	ON (inventory_supplier.supplier_id = p21_view_invoice_line.supplier_id)
	AND	(inventory_supplier.inv_mast_uid = p21_view_invoice_line.inv_mast_uid)
LEFT JOIN oe_line_ud WITH(NOLOCK)
	ON oe_line_ud.line_no = p21_view_invoice_line.oe_line_number
	AND oe_line_ud.order_no = p21_view_invoice_line.order_no
LEFT JOIN p21_view_class AS item_class1_desc
	ON item_class1_desc.class_id = inv_mast.class_id1
	AND item_class1_desc.class_type = 'IV'
	AND item_class1_desc.class_number = 1
	AND item_class1_desc.delete_flag = 'N'
LEFT JOIN p21_view_class AS item_class2_desc
	ON item_class2_desc.class_id = inv_mast.class_id2
	AND item_class2_desc.class_type = 'IV'
	AND item_class2_desc.class_number = 2
	AND item_class2_desc.delete_flag = 'N'
LEFT JOIN customer_ud WITH(NOLOCK)
	ON customer_ud.company_id = invoice_hdr.company_no
	AND customer_ud.customer_id = invoice_hdr.sold_to_customer_id
LEFT JOIN oe_hdr_ud WITH(NOLOCK)
	ON oe_hdr_ud.order_no = p21_view_invoice_line.order_no
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
LEFT JOIN p21_view_codes AS order_source
	ON order_source.code_no = oe_hdr.source_code_no
	AND order_source.code_group_no = 1012
LEFT JOIN inv_mast_ud WITH(NOLOCK)
	ON inv_mast.inv_mast_uid = inv_mast_ud.inv_mast_uid
-- supplier from primary_supplier_id on inv_loc (mostly for legacy data)
LEFT JOIN supplier supplier_inv_loc  WITH (NOLOCK)
	ON (inv_loc.primary_supplier_id = supplier_inv_loc.supplier_id)
LEFT JOIN address AS corp_addr WITH(NOLOCK)
	ON corp_addr.id = address.corp_address_id
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
-- number_of_invoice_lines (was an all-history GROUP BY derived table)
OUTER APPLY (
	SELECT COUNT(*) AS counter
	FROM invoice_line WITH (NOLOCK)
	WHERE invoice_line.invoice_no = invoice_hdr.invoice_no
		AND invoice_line.other_charge_item = 'N'
		AND invoice_line.tax_item = 'N'
		AND (invoice_line.invoice_line_type = 0
			--this is the top lot group item
			OR (invoice_line.invoice_line_type = 4 AND invoice_line.invoice_line_uid_parent = 0))
		AND invoice_line.item_id NOT IN ('DOWNPAYMENT','PREPAYMENT')
		AND invoice_line.qty_shipped <> 0.0000
		AND invoice_line.item_id <> 'ADVANCE BILL AMOUNT'
) AS invoice_line_summary
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
GO

GRANT SELECT ON dbo.asi_sales_history_report_view_roii_costs TO p21_application_role
GO
GRANT SELECT ON dbo.asi_sales_history_report_view_roii_costs TO PxxiUser
GO
