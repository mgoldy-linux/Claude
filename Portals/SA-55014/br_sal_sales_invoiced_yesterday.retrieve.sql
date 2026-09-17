-----------------------
-- Created by Karen Benish
-- August 10, 2016
-- Portal for John to see invoiced sales yesterday
-- 1/31/2018: Added job name
-- 1/9/2018: Added parameters to optionally filter results
-- 9/8/2016: Added rebate due amount
-- 2026-09-16: Retired kb_sales_history_report_view / kb_fn_date_rng_calc /
--   kb_fnt_get_user_loc — replaced with dbo.asi_fnt_sa55014_sales_invoiced_yesterday
-----------------------
SELECT
	invoice_no
	,line_no
	,order_no
	,oe_line_number
	,invoice_date
	,customer_id
	,customer_name
	,product_group_desc
	,item_id
	,extended_desc
	,qty_ordered
	,base_unit
	,qty_shipped
	,unit_price
	,sales_price_home
	,line_other_cost_home
	,gross_profit_dollars
	,rebate_due
	,other_cost_edited
	,manual_price_overide
	,job_name
	,price_page
	,printed
	,price_family_desc
FROM dbo.asi_fnt_sa55014_sales_invoiced_yesterday('<user_id>', :mfg)
" arguments=(("mfg", string)) )
