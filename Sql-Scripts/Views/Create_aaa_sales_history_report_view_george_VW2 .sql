/*
	Might need all extended description
	select top 5 v.item_id, v.item_desc, m.extended_desc
	from dbo.p21_sales_history_report_view v
	join dbo.inv_mast m
	on v.inv_mast_uid = m.inv_mast_uid
	08/31/2022 - clean up per gdib, update salesrep, add ext description
*/
--use P21Play;
use P21;

/*
if OBJECT_ID ('aaa_sales_history_report_view_george_VW2', 'V') is not null
drop view aaa_sales_history_report_view_george_VW2;
go

create view [dbo].[aaa_sales_history_report_view_george_VW2] AS
*/

SELECT gv.branch_id, gv.customer_id, gv.customer_name, gv.class_1id, gv.class_2id, c.salesrep_id AS Customer_rep_id, gv.period, gv.year_for_period, gv.invoice_date,
 gv.product_group_desc, gv.item_id, gv.item_desc, m.extended_desc, gv.qty_shipped, gv.sales_price_home,gv.po_no, gv.ship2_name
FROM dbo.p21_sales_history_report_view AS gv 
INNER JOIN dbo.customer AS c 
ON gv.customer_id = c.customer_id
join dbo.inv_mast m
on gv.inv_mast_uid = m.inv_mast_uid
WHERE (gv.company_id = '1') AND (NOT (gv.invoice_line_type = 981 OR gv.invoice_line_type = 982 OR gv.invoice_line_type = 1577 OR gv.invoice_line_type = 1719)) 
AND (gv.vendor_consigned = 'N') AND (gv.projected_order = 'N') AND (gv.detail_type IS NULL OR gv.detail_type = 0) AND
(gv.progress_bill_flag = 'N' OR gv.progress_bill_flag IS NULL) AND (gv.consignment_flag = 'N') and product_group_id != 'OTHERCHG' and invoice_date > '2018-07-01'

go
/*
grant select on object::aaa_sales_history_report_view_george_VW2 to p21_application_role
grant select on object::aaa_sales_history_report_view_george_VW2 to PxxiUser
grant select on object::aaa_sales_history_report_view_george_VW2 to [PTIDOM\P21Users]
*/
