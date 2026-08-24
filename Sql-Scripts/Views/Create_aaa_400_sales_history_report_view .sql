/*
	09/28/22 - modify aaa_sales_history_report_view_11_13_19 for Lisa
*/
use P21Play;
--use P21;

/*
if OBJECT_ID ('aaa_400_sales_history_report_view', 'V') is not null
drop view aaa_400_sales_history_report_view;
go

create view [dbo].[aaa_400_sales_history_report_view] AS
*/

SELECT ship_to_id, item_id, format(invoice_date,'MM/dd/yyyy')[invoice_date], po_no, order_no, invoice_no, branch_description, product_group_desc, sales_location_name, supplier_name, company_name, item_desc, qty_shipped, unit_of_measure, oe_line_assembly, parent_oe_line_uid, branch_id, v.customer_id,c.legacy_id, period, product_group_id, sales_location_id, v.salesrep_id, supplier_id, taker, year_for_period, v.customer_name, other_charge_item, unit_size, sales_price_home, currency_desc, v.currency_id, home_currency_id, line_no, year_and_period, invoice_adjustment_type, ship2_name, contract_no, assembly_sales_price, assembly_cogs_amt_home, cogs_amount_home, oe_line_number, order_type AS order_type1, mfr_vendor_id, mfr_vendor_name, job_name, number_of_invoice_lines, invoice_line_type, sales_price, line_other_cost_home, line_commission_cost_home, assembly_cogs_amount, cogs_amount, line_other_cost, line_commission_cost, progress_bill_flag, prod_order_number, prod_order_date, assembly_sales_price_home, invoice_line_uid_parent, assembly_other_cost_home, assembly_commission_cost_home, assembly_other_cost, assembly_commission_cost, salesrep_info, branch_info, customer_info, period_year_info, product_group_info, sales_location_info, ship_to_info, supplier_info, taker_info, v.company_id, corp_address_id, v.class_1id, v.class_2id, v.class_3id, v.class_4id, v.class_5id, stockable, rma_flag, vendor_consigned, projected_order, detail_type, sum_cogs, sum_other_cost, sum_cmsn_cost, sum_cogs_home, sum_other_cost_home, sum_cmsn_cost_home, dealer_commission_ext_amt, default_sales_unit_size, default_sales_unit_of_measure, revision_level, consignment_flag, v.source_type_cd, gallons_shipped, gallons_system_setting, inv_no_display, order_type, 
CASE
 v.period WHEN '1' THEN 'Jul' WHEN '2' THEN 'Aug' WHEN '3' THEN 'Sep' WHEN '4' THEN 'Oct' WHEN '5' THEN 'Nov' WHEN '6' THEN 'Dec' WHEN '7' THEN 'Jan' WHEN '8' THEN 'Feb' WHEN
 '9' THEN 'Mar' WHEN '10' THEN 'Apr' WHEN '11' THEN 'May' WHEN '12' THEN 'Jun' ELSE 'Review' END[period_Desc]
FROM dbo.p21_sales_history_report_view v
join dbo.customer c
on v.customer_id =c.customer_id
WHERE (branch_id in (400,410)) and (v.company_id = '1') AND (NOT (invoice_line_type = 981 OR invoice_line_type = 982 OR invoice_line_type = 1577 OR invoice_line_type = 1719)) AND (vendor_consigned = 'N') AND (projected_order = 'N') AND (detail_type IS NULL OR detail_type = 0) AND (progress_bill_flag = 'N' OR progress_bill_flag IS NULL) AND (consignment_flag = 'N')

go
/*
grant select on object::aaa_400_sales_history_report_view to p21_application_role
grant select on object::aaa_400_sales_history_report_view to PxxiUser
grant select on object::aaa_400_sales_history_report_view to [PTIDOM\P21Users]
*/
