USE P21;
GO
CREATE OR ALTER VIEW dbo.asi_3yr_sales_history_report_view
AS
/* Karen's NOTES:
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
		other_other_charge_cost_home (is always zero for some reason)
		extended_price_home (is always zero for some reason)
		commissionable_gross_profit (there's a _home version)
		commissionable_gross_profit_home (was calculating using invoice_line.gross_profit; is now using invoice_line.sales_price_home - invoice_line.cogs_amount_home)
		invoice_no (is in the group by, so cannot be added as a column, but is in the shrv.invoice_number column for the final report)
		tax_home (not useful)
		qty_shipped (there's a qty_shipped_home in the underlying query that is then cast as qty_shipped in the view)
		gross_profit_percent (not useful)
		gross_profit_percent_home (not useful)
		invoice_number (is in the group by, but in the final report is in the invoice_number column)
	To the original view, these fields were added (and why):
		invoice_date
		invoice_number
		year_for_period
		period_for_period
		week_for_period
		customer_class1 (the column name)
		*/
with opsregion (customer_id, territory_id, territory_desc)
as
(
select c.customer_id, territory_id, territory_desc
from customer c
left join territory_x_customer txc
on c.customer_id = txc.customer_id
left join territory t
on txc.territory_uid = t.territory_uid
where t.territory_id like 'SR%' and txc.row_status_flag = 704 and c.delete_flag = 'N'
)
SELECT territory_desc,
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
	,kb_view_invoice_line_rewards.incentive_rewards
	,kb_view_invoice_line_rewards.coop_rewards
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
		WHEN ROUND(COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0.0000), 4) = 0.0000 THEN p21_view_invoice_line.unit_price
		-- Adjust unit price by removing reward (reward is already divided in this view, if many invoice lines to one order line)
		-- Divide reward by quantity purchased, since reward is a total for the line
		ELSE ROUND(p21_view_invoice_line.unit_price - (kb_view_invoice_line_rewards.incentive_rewards / 
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
	-- Sales Price Home Calculation
	,(CASE COALESCE(oe_hdr_advance_billing.advance_bill, 'N')
		WHEN 'Y' THEN ((p21_view_invoice_line.QTY_SHIPPED * (p21_view_invoice_line.UNIT_PRICE_home/
			COALESCE(p21_view_invoice_line.pricing_unit_size,1))) - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0))
		WHEN 'N' THEN	   	
			CASE COALESCE (oe_line.pricing_option,0)			 		
				-- pricing by component
				WHEN 1 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent	
						WHEN 0 THEN 0 
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) 
					END)
				-- pricing by assembly using component prices
				WHEN 2 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) 
						ELSE 0 
					END)
				-- pricing by assembly
				WHEN 3 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) 
						ELSE 0 
					END)
				-- 4s have a zero for extended price for whatever reason
				WHEN 4 THEN  0 
				-- most of our orders (not assembly/component)
				WHEN 0 THEN ( 
					CASE oe_hdr.order_type 
						WHEN 1706 THEN (
							CASE 
								WHEN p21_view_invoice_line.invoice_line_type = 0 THEN drv_sumlines.sum_price_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) -- + COALESCE(drv_sumtaxes.sum_taxes,0)
								ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)	
							END)
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)
					END )	
				ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)
			END
	END) AS sales_price_home
	
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

	-- Line_other_cost_home calculation, adjusted for co-op
	,CASE COALESCE (oe_line.pricing_option, 0)
		WHEN 1 THEN ( 
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN 0 
				ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
			END)
		WHEN 2 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
				ELSE 0 
			END)
		WHEN 3 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
				ELSE 0 
			END)
		-- kb added when 
		WHEN 4 THEN (
			CASE p21_view_invoice_line.invoice_line_uid_parent
				WHEN 0 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
				ELSE 0 
			END)
		--WHEN 1 THEN (
		--	CASE p21_view_invoice_line.invoice_line_uid_parent
		--		WHEN 0 THEN 0 
		--		ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
		--	END)
		WHEN 0 THEN  (
			CASE WHEN oe_hdr.order_type = 1706 THEN (
				CASE p21_view_invoice_line.invoice_line_type
					WHEN 1577 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.hours_worked) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
					WHEN 1719 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
					ELSE drv_sumlines.sum_other_cost_home - kb_view_invoice_line_rewards.coop_rewards
				END)
			ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
		END)
		ELSE 	(p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
	END AS inflated_line_other_cost_home

 	-- Line_other_cost_home calculation, ** NOT ADJUSTED FOR CO-OP **
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
					WHEN 1577 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.hours_worked) 
					WHEN 1719 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) 
					ELSE drv_sumlines.sum_other_cost_home 
				END)
			ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) 
		END)
		ELSE 	(p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) 
	END AS line_other_cost_home 
-- gross_profit_dollars calculation, ** NOT ADJUSTED FOR CO-OP ** but adjusted for incentive points
	-- take the Sales Price Home Calculation...
	,(CASE COALESCE(oe_hdr_advance_billing.advance_bill, 'N')
		WHEN 'Y' THEN ((p21_view_invoice_line.QTY_SHIPPED * (p21_view_invoice_line.UNIT_PRICE_home/
			COALESCE(p21_view_invoice_line.pricing_unit_size,1))) - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0))
		WHEN 'N' THEN	   	
			CASE COALESCE (oe_line.pricing_option,0)			 		
				-- pricing by component
				WHEN 1 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent	
						WHEN 0 THEN 0 
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) 
					END)
				-- pricing by assembly using component prices
				WHEN 2 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) 
						ELSE 0 
					END)
				-- pricing by assembly
				WHEN 3 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) 
						ELSE 0 
					END)
				-- 4s have a zero for extended price for whatever reason
				WHEN 4 THEN  0 
				-- most of our orders (not assembly/component)
				WHEN 0 THEN ( 
					CASE oe_hdr.order_type 
						WHEN 1706 THEN (
							CASE 
								WHEN p21_view_invoice_line.invoice_line_type = 0 THEN drv_sumlines.sum_price_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) -- + COALESCE(drv_sumtaxes.sum_taxes,0)
								ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)	
							END)
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)
					END )	
				ELSE p21_view_invoice_line.EXTENDED_PRICE_home - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)
			END
	END) 
	- 	-- ...and subtract the Line Other Cost Home Calculation...
	(CASE COALESCE (oe_line.pricing_option, 0)
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
		--		ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) + COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0)
		--	END)
		WHEN 0 THEN  (
			CASE WHEN oe_hdr.order_type = 1706 THEN (
				CASE p21_view_invoice_line.invoice_line_type
					WHEN 1577 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.hours_worked) 
					WHEN 1719 THEN (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) 
					ELSE drv_sumlines.sum_other_cost_home 
				END)
			ELSE (p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) 
		END)
		ELSE 	(p21_view_invoice_line.other_cost_home * p21_view_invoice_line.qty_shipped) 
	END) --...and tada! 
	AS gross_profit_dollars 
	

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
						ELSE p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)
					END)
				WHEN 2 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)
						ELSE 0.0000 
					END)
				WHEN 3 THEN ( 
					CASE p21_view_invoice_line.invoice_line_uid_parent
						WHEN 0 THEN p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) 
						ELSE 0.0000 
					END)
				WHEN 4 THEN  0.0000 
				ELSE 	p21_view_invoice_line.EXTENDED_PRICE_home + COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0)
			END 
		WHEN 'N' THEN  0.0000
	END AS other_charge_line_price_home

	--,(p21_view_invoice_line.commission_cost * COALESCE(p21_view_invoice_line.sales_unit_size, 1)) AS net_moving_avg_unit_cost -- commission_cost
	,(p21_view_invoice_line.other_cost * COALESCE(p21_view_invoice_line.sales_unit_size, 1)) AS deflated_unit_other_cost -- other_cost 
	-- Net Unit Other Cost adjusted for co-op
	,CASE p21_view_invoice_line.qty_shipped WHEN 0 THEN p21_view_invoice_line.other_cost
		ELSE 
		(p21_view_invoice_line.other_cost + 
			(COALESCE(kb_view_invoice_line_rewards.coop_rewards, 0) / p21_view_invoice_line.qty_shipped)
			) * COALESCE(p21_view_invoice_line.sales_unit_size, 1)
	END AS inflated_net_unit_other_cost -- other_cost 
	
	-- Net Unit Other Cost ** NOT ADJUSTED FOR CO-OP **
	,CASE p21_view_invoice_line.qty_shipped WHEN 0 THEN p21_view_invoice_line.other_cost
		ELSE 
		(p21_view_invoice_line.other_cost) * COALESCE(p21_view_invoice_line.sales_unit_size, 1)
	END AS net_unit_other_cost -- other_cost  
	
	,p21_view_invoice_line.extended_price AS inflated_detail_price
	,p21_view_invoice_line.extended_price - COALESCE(kb_view_invoice_line_rewards.incentive_rewards, 0) AS detail_price
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
	--,oe_line.sales_cost AS gross_moving_avg_unit_cost -- sales_cost
	,oe_line_lot_billing.price_basis --'I' indicates ItemizedLotBilling and 'N' indicates NestedLotBilling
	,oe_line.lot_bill
	,oe_line.detail_type
	--,(COALESCE(oe_line_dealer_commission.dealer_commission_amt,0) * p21_view_invoice_line.qty_shipped / COALESCE(NULLIF(p21_view_invoice_line.pricing_unit_size,0), 1 )) AS dealer_commission_ext_amt
	,oe_line.pricing_option
	,p21_view_invoice_line.job_price_line_uid
	,oe_line.manual_price_overide
	,oe_line.system_calc_unit_price
	,CASE COALESCE(kb_view_invoice_line_rewards.coop_rewards,0) + COALESCE(kb_view_invoice_line_rewards.incentive_rewards,0) 
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS rewards_flag
	,CASE COALESCE(kb_view_invoice_line_rewards.oe_incentive_rewards,0)
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS oe_line_rewards_flag
	,CASE COALESCE(kb_view_invoice_line_rewards.auto_incentive_rewards,0)
		WHEN 0 THEN 'N'
		ELSE 'Y'
	END AS automatic_incentive_rewards_flag
	,CASE COALESCE(kb_view_invoice_line_rewards.coop_rewards,0) 
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
	-- KB removed 5-18-2020
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
	,inv_mast_ud.division AS division -- mg add SA 29598 - 20250827
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
	, -- COALESCE(invoice_line_ud.updated_salesrep_id, oe_line_ud.updated_salesrep_id, 0) AS salesrep_id --updated
	COALESCE(invoice_line_ud.updated_salesrep_id, 
		oe_line_ud.updated_salesrep_id, 
		oe_line_ud.oe_salesrep_id , 
		--dbo.kb_fn_get_salesrep(invoice_hdr.company_no,
		--	invoice_hdr.sold_to_customer_id, 
		--	inv_mast.commission_class_id ),
		0 ) AS salesrep_id


	-- KB ADD/EDIT 2020 06 Sales manager change
	,salesrep_contact.id AS salesrep_id_varchar
	,CASE WHEN LEN(RTRIM(LTRIM(ISNULL(salesrep_contact_ud.nickname,'')))) > 0 THEN salesrep_contact_ud.nickname ELSE salesrep_contact.first_name END + ' ' + salesrep_contact.last_name AS salesrep_name
	,COALESCE(manager_contact.id, '0') AS manager_id
	,COALESCE(--manager_contact.first_name + ' ' + manager_contact.last_name
		dbo.kb_fn_get_sales_manager_names(CONVERT(INT,salesrep_contact.id), inv_mast.commission_class_id, NULL)
		,'None') AS manager_name
	
	
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
INNER JOIN address_history  WITH (NOLOCK) 
	ON invoice_hdr.sold_to_ah_uid = address_history.address_history_uid
/* LEFT JOINS */
LEFT OUTER JOIN invoice_hdr_salesrep  WITH (NOLOCK) -- keep this because of the primary salesrep WHERE clause below
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
LEFT OUTER JOIN location AS oe_line_ship_loc (NOLOCK) 
	ON (oe_line.ship_loc_id = oe_line_ship_loc.location_id)
-- 12.13 JVC 08/21/13 Scopus 1162712: Join to location to get the sales location from invoice
LEFT OUTER JOIN location AS inv_sales_loc (NOLOCK) 
	ON (invoice_hdr.sales_location_id = inv_sales_loc.location_id)
LEFT OUTER JOIN shipping_route  WITH (NOLOCK) 
	ON (invoice_hdr.shipping_route_uid = shipping_route.shipping_route_uid)
LEFT OUTER JOIN inv_mast  WITH (NOLOCK) 
	ON (p21_view_invoice_line.inv_mast_uid = inv_mast.inv_mast_uid)
LEFT OUTER JOIN price_page WITH (NOLOCK) 
	ON price_page.price_page_uid = COALESCE(p21_view_invoice_line.cost_price_page_uid, oe_line.cost_price_page_uid, oe_line.price_page_uid)
--12.13 YCHEN 10/09/13 - Scopus#1151323: used job_price_line_a,job_price_hdr_a ,job_price_line_b, job_price_hdr_b, added join to price_page.
LEFT OUTER JOIN job_price_line  WITH (NOLOCK) 
	ON job_price_line.job_price_line_uid = p21_view_invoice_line.job_price_line_uid
LEFT OUTER JOIN job_price_hdr  WITH (NOLOCK) 
	ON job_price_hdr.job_price_hdr_uid = job_price_line.job_price_hdr_uid 
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
INNER JOIN currency_hdr  WITH (NOLOCK) 
	ON currency_hdr.currency_id= customer.currency_id
LEFT OUTER JOIN oe_line_lot_billing  WITH (NOLOCK) 
	ON oe_line_lot_billing.oe_line_uid = oe_line.oe_line_uid
LEFT OUTER JOIN (
	SELECT	
		invoice_line.invoice_no
		, COUNT(*) AS counter
	FROM	
		invoice_line WITH (NOLOCK)
	WHERE	
		invoice_line.other_charge_item = 'N'
		AND invoice_line.tax_item = 'N'
		AND (invoice_line.invoice_line_type = 0
		--this is the top lot group item
		 OR	(invoice_line.invoice_line_type = 4
		AND invoice_line.invoice_line_uid_parent = 0))
		AND invoice_line.item_id NOT IN ('DOWNPAYMENT','PREPAYMENT')
		AND 
		(
			(
				invoice_line.qty_shipped > 0.0000  
				AND invoice_line.item_id <> 'ADVANCE BILL AMOUNT'
			) 
			OR
			(
				invoice_line.qty_shipped < 0.0000  
				AND invoice_line.item_id <> 'ADVANCE BILL AMOUNT'
			)
		)	
	GROUP BY 	
		invoice_line.invoice_no
	) AS invoice_line_summary
	ON invoice_line_summary.invoice_no = invoice_hdr.invoice_no
LEFT JOIN oe_hdr_mfr  WITH (NOLOCK) 
	ON oe_hdr_mfr.oe_hdr_uid = oe_hdr.oe_hdr_uid
LEFT JOIN vendor  WITH (NOLOCK) 
	ON vendor.vendor_id = oe_hdr_mfr.vendor_id
	AND vendor.company_id = invoice_hdr.company_no
LEFT JOIN jc_job  WITH (NOLOCK) 
	ON jc_job.job_id = invoice_hdr.job_id	

LEFT JOIN (
	SELECT 
		SUM(invoice_line.cogs_amount) sum_cogs,
		SUM(invoice_line.cogs_amount_home) sum_cogs_home,
		SUM(invoice_line.extended_price) sum_price,
		SUM(invoice_line.extended_price_home) sum_price_home,
		SUM(CASE invoice_line.invoice_line_type
			WHEN 1577 THEN 
				(CASE oe_hdr.rma_flag  -- GGR Scopus 1210407 Convert to negative the commission cost when is a Service Order RMA.
					WHEN 'Y' THEN  (-1)*(invoice_line.commission_cost * invoice_line.hours_worked)
					ELSE invoice_line.commission_cost * invoice_line.hours_worked
				END)
			WHEN 1719 THEN invoice_line.commission_cost*invoice_line.qty_shipped
		END) sum_cmsn_cost,
		SUM(CASE invoice_line.invoice_line_type
			WHEN 1577 THEN invoice_line.other_cost*invoice_line.hours_worked
			WHEN 1719 THEN invoice_line.other_cost*invoice_line.qty_shipped
		END) sum_other_cost,
		SUM(CASE invoice_line.invoice_line_type
			WHEN 1577 THEN invoice_line.other_cost_home*invoice_line.hours_worked
			WHEN 1719 THEN invoice_line.other_cost_home*invoice_line.qty_shipped
		END) sum_other_cost_home,
		SUM(CASE  invoice_line.invoice_line_type
			WHEN 1577 THEN (
				CASE oe_hdr.rma_flag  -- GGR Scopus 1210407 Convert to negative the commission cost when is a Service Order RMA.
					WHEN 'Y' THEN  (-1)*(invoice_line.commission_cost_home * invoice_line.hours_worked)
					ELSE invoice_line.commission_cost_home * invoice_line.hours_worked
				END)
			WHEN 1719 THEN invoice_line.commission_cost_home*invoice_line.qty_shipped
		END) sum_cmsn_cost_home,
		invoice_line.invoice_line_uid_parent
	FROM p21_view_invoice_line invoice_line
	-- GGR Scopus 1210407 Add the joins neded to use the oe_hdr.rma_flag.
	INNER JOIN invoice_hdr WITH (NOLOCK) 
		ON (invoice_hdr.invoice_no = invoice_line.invoice_no)
	LEFT OUTER JOIN oe_hdr  WITH (NOLOCK) 
		ON invoice_hdr.order_no = oe_hdr.order_no
	WHERE 
		-- invoice line type is a Part or Labor (respectively)
		invoice_line.invoice_line_type IN (1719, 1577)
	GROUP BY invoice_line.invoice_line_uid_parent
) AS drv_sumlines 
	ON (drv_sumlines.invoice_line_uid_parent = p21_view_invoice_line.invoice_line_uid)

LEFT JOIN oe_hdr_progress_billing  WITH (NOLOCK)
	ON oe_hdr_progress_billing.order_no = oe_hdr.order_no  
    AND oe_hdr_progress_billing.progress_bill_flag = 'Y'    
LEFT JOIN prod_order_line_link WITH (NOLOCK) 
	ON prod_order_line_link.transaction_uid = oe_line.oe_line_uid  
    AND prod_order_line_link.trans_type = 'O'  
	AND oe_hdr_progress_billing.progress_bill_flag = 'Y'
LEFT JOIN prod_order_hdr  WITH (NOLOCK) 
	ON prod_order_hdr.prod_order_number = prod_order_line_link.prod_order_number
LEFT JOIN progress_billing_x_invoice_hdr  WITH (NOLOCK) 
	ON progress_billing_x_invoice_hdr.oe_hdr_progress_billing_uid = 	oe_hdr_progress_billing.oe_hdr_progress_billing_uid 
	AND progress_billing_x_invoice_hdr.invoice_no= invoice_hdr.invoice_no 		
-- Pil RSM 06/23/09 Scopus 794907: Join back to the oe_line_dealer_commission table.
LEFT JOIN oe_line_dealer_commission WITH(NOLOCK) 
	ON oe_line_dealer_commission.oe_line_uid = oe_line.oe_line_uid
LEFT JOIN item_uom  WITH(NOLOCK)
	ON inv_mast.inv_mast_uid = item_uom.inv_mast_uid
	AND inv_mast.default_selling_unit = item_uom.unit_of_measure
-- KB removed 5-18-2020
--LEFT JOIN revision_transaction  WITH (NOLOCK) 
--	ON CAST(revision_transaction.transaction_no AS VARCHAR(8)) = oe_line.order_no  -- KB fix 7-26-19
--    AND CAST(revision_transaction.transaction_line_no AS DECIMAL(19,0)) = oe_line.line_no -- KB fix 7-26-19
--	AND revision_transaction.transaction_code_no IN (1533, 1721)
--LEFT JOIN item_revision  WITH (NOLOCK) 
--	ON item_revision.item_revision_uid = revision_transaction.item_revision_uid
-- DAK 05/29/2009 Scopus: 793123
LEFT JOIN (	
	SELECT	
		SUM(p21_view_invoice_line.commission_cost) commission_cost
		,SUM(p21_view_invoice_line.commission_cost_home) commission_cost_home
		,p21_view_invoice_line.invoice_line_uid_parent
	FROM	p21_view_invoice_line
	WHERE	p21_view_invoice_line.invoice_line_type = 4 
		AND	p21_view_invoice_line.invoice_line_uid_parent <> 0
	GROUP BY 
		p21_view_invoice_line.invoice_line_uid_parent
) AS drv_nested_lot_header_comm_cost 
	ON (drv_nested_lot_header_comm_cost.invoice_line_uid_parent = p21_view_invoice_line.invoice_line_uid)
--SAR 06/11/2009 - Add Oil functionality.
LEFT JOIN system_setting AS system_setting_Gallon  WITH (NOLOCK) 
	ON (system_setting_Gallon.configuration_id = 0) 
	AND (system_setting_Gallon.name = 'Gallon_UOM')
LEFT JOIN item_uom AS item_uom_gallon  WITH (NOLOCK) 
	ON (item_uom_gallon.inv_mast_uid = p21_view_invoice_line.inv_mast_uid)
	AND (item_uom_gallon.unit_of_measure = system_setting_Gallon.value)
-- GGR - 01/22/15 - Scopus 1276785 - Exclude deleted item_uom records.
	AND  item_uom_gallon.delete_flag = 'N'
--JC - Projx#46532 - System pricing - Add info from order_floor_plan_xref_10002
LEFT JOIN order_floor_plan_xref_10002 WITH(NOLOCK) 
	ON (order_floor_plan_xref_10002.oe_hdr_uid = oe_hdr.oe_hdr_uid)
--ATG 04/15/2015 - Feature 58270: Adding Left Join with inventory_supplier, so we can access the manufacturing_class_id column
LEFT JOIN inventory_supplier WITH (NOLOCK) 
	ON (inventory_supplier.supplier_id = p21_view_invoice_line.supplier_id)
	AND	(inventory_supplier.inv_mast_uid = p21_view_invoice_line.inv_mast_uid)
-- KB Join OE Line UD table
LEFT JOIN oe_line_ud WITH(NOLOCK)
	ON oe_line_ud.line_no = p21_view_invoice_line.oe_line_number
	AND oe_line_ud.order_no = p21_view_invoice_line.order_no
-- KB Join Class table for item class 1 Description
LEFT JOIN p21_view_class AS item_class1_desc 
	ON item_class1_desc.class_id = inv_mast.class_id1
	AND item_class1_desc.class_type = 'IV'
	AND item_class1_desc.class_number = 1
	AND item_class1_desc.delete_flag = 'N'
-- KB Join Class table for item class 2 Description
LEFT JOIN p21_view_class AS item_class2_desc 
	ON item_class2_desc.class_id = inv_mast.class_id2
	AND item_class2_desc.class_type = 'IV'
	AND item_class2_desc.class_number = 2
	AND item_class2_desc.delete_flag = 'N'
-- KB Join custom customer table for Closed and other custom fields
LEFT JOIN customer_ud WITH(NOLOCK) 
	ON customer_ud.company_id = invoice_hdr.company_no
	AND customer_ud.customer_id = invoice_hdr.sold_to_customer_id
-- KB Join custom order header table for custom order contact field
LEFT JOIN oe_hdr_ud WITH(NOLOCK)
	ON oe_hdr_ud.order_no = p21_view_invoice_line.order_no
-- KB Join custom invoice line table for salesrep and other custom fields
LEFT JOIN invoice_line_ud WITH(NOLOCK)
	ON invoice_hdr.invoice_no = invoice_line_ud.invoice_no
	AND p21_view_invoice_line.line_no = invoice_line_ud.line_no
-- KB Join address table for salesrep name & manager name
LEFT JOIN contacts AS salesrep_contact WITH(NOLOCK)
	ON salesrep_contact.id = CONVERT(VARCHAR(16),COALESCE(invoice_line_ud.updated_salesrep_id, 
		oe_line_ud.updated_salesrep_id, 
		oe_line_ud.oe_salesrep_id , 
		--dbo.kb_fn_get_salesrep(invoice_hdr.company_no,
		--	invoice_hdr.sold_to_customer_id, 
		--	inv_mast.commission_class_id ),
		0 ))
LEFT JOIN contacts_ud AS salesrep_contact_ud ON salesrep_contact.id = salesrep_contact_ud.id
LEFT JOIN contacts AS manager_contact 
	-- KB add 2020 Sales Manager logic change
	--ON manager_contact.id = salesrep_contact.sales_manager_id
	ON manager_contact.id = dbo.kb_fn_get_sales_manager(CONVERT(INT, salesrep_contact.id), inv_mast.commission_class_id, NULL)



-- KB Join rewards view
LEFT JOIN kb_view_invoice_line_rewards
	ON p21_view_invoice_line.invoice_no = kb_view_invoice_line_rewards.invoice_no
	AND p21_view_invoice_line.line_no = kb_view_invoice_line_rewards.line_no
-- KB Join order source type codes
LEFT JOIN p21_view_codes AS order_source
	ON order_source.code_no = oe_hdr.source_code_no
	AND order_source.code_group_no = 1012
-- KB Join inv_mast_ud for Display, Update & Specials List checkboxes
LEFT JOIN inv_mast_ud WITH(NOLOCK)
	ON inv_mast.inv_mast_uid = inv_mast_ud.inv_mast_uid
-- KB Join supplier from primary_supplier_id on inv_loc table (mostly for legacy data)
LEFT JOIN supplier supplier_inv_loc  WITH (NOLOCK) 
	ON (inv_loc.primary_supplier_id = supplier_inv_loc.supplier_id)
-- KB Join address for corporate address name
LEFT JOIN address AS corp_addr WITH(NOLOCK)
	ON corp_addr.id = address.corp_address_id
-- KB Join for finding directs
LEFT JOIN (SELECT DISTINCT invoice_no FROM kb_view_direct_invoices_incl_rebills) AS direct
	ON direct.invoice_no = invoice_hdr.invoice_no
-- KB Join for adding Price Family
LEFT JOIN p21_view_price_family AS pf
	ON pf.price_family_uid = inv_mast.default_price_family_uid
---- KB Join for primary supplier manufacturing_class_id
--LEFT JOIN inventory_supplier AS primary_inventory_supplier WITH (NOLOCK) 
--	ON inventory_supplier.supplier_id = inv_loc.primary_supplier_id
--	AND	inventory_supplier.inv_mast_uid = p21_view_invoice_line.inv_mast_uid
-- KB Join for location 100 product group
LEFT JOIN inv_loc AS inv_loc100 WITH (NOLOCK) 
	ON inv_loc100.location_id = 100 AND inv_loc100.company_id = invoice_hdr.company_no
	AND	inv_loc100.inv_mast_uid = p21_view_invoice_line.inv_mast_uid
LEFT JOIN product_group  WITH (NOLOCK) 
	ON p21_view_invoice_line.company_id = product_group.company_id
	AND COALESCE(
			CASE inv_loc.product_group_id WHEN '' THEN NULL ELSE inv_loc.product_group_id END,
			CASE inv_loc100.product_group_id WHEN '' THEN NULL ELSE inv_loc100.product_group_id END
		) = product_group.product_group_id
-- KB add 2020 Sales Manager logic change
LEFT JOIN contacts_ud AS salesrep_ud
ON salesrep_ud.id = salesrep_contact.id
Join opsRegion 
on customer.customer_id = opsregion.customer_id
WHERE
	-- Only show approved invoices	
	invoice_hdr.approved = 'Y'
	
	-- 2 FIXES FOR IMPORTED HISTORICAL SALES DATA
	AND ( -- omits these item ids for imported invoices because they didn't import nicely and shouldn't be in sales reports
		-- invoice was not imported
		ISNULL(invoice_hdr.source_type_cd,0) <> 1661
		-- or invoice is not for one of the imported poorly items
		OR p21_view_invoice_line.item_id NOT IN (
			-- All Tile / Dancik poor items
			'DELIVERY', 'DISC', 'FUEL CHG', 'FUND', 'HAND', 'MISC', 'OVERPAYMENT', 'INBOUND FUEL SURCHARGE',
			-- CCS / Solar poor items
			'BALANCING_ITEM','FREIGHT_ITEM','HANDLING_ITEM')
	)
	AND ( -- omits zero dollar invoices for non-imported invoices (keeps zero dollar invoices for imports, because those aren't always as zero as they seem)
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
	
	-- Eliminates duplicate invoice lines
	AND	invoice_hdr_salesrep.primary_salesrep = 'Y'
	
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

	-- Add this line to filter by the last 3 years
	AND invoice_hdr.invoice_date >= DATEADD(year, -3, GETDATE())
