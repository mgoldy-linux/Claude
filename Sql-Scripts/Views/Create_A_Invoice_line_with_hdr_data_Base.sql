-- add territpty to A_il_with_Hdr_data_Olivia view
use P21Sand;
--use P21Play;
--use P21;
/*
if OBJECT_ID ('A_Invoice_line_with_hdr_data_Base', 'V') is not null
drop view A_Invoice_line_with_hdr_data_Base;
go

create view [dbo].[A_Invoice_line_with_hdr_data_Base] AS
*/

SELECT	il.invoice_no, il.qty_requested, il.qty_shipped, il.unit_of_measure, il.item_id, il.item_desc, il.unit_price, 
		il.extended_price, il.gl_revenue_account_no, il.gl_salse_tax_account_no, il.gl_cogs, il.gl_inventory, il.date_created, 
		il.date_last_modified, il.last_maintained_by, il.order_no, il.cogs_amount, il.customer_part_number, il.company_id, 
		il.tax_item, il.line_no, il.sales_cost, il.commission_cost, il.other_cost, il.oe_line_number, il.other_charge_item, 
		il.invoice_line_uid, il.invoice_line_uid_parent, il.inv_mast_uid, il.invoice_line_type, il.product_group_id, il.created_by, 
		il.processed_flag, il.sales_discount_group_id, ih.order_no AS Expr1, ih.order_date, ih.invoice_date, ih.customer_id, 
		ih.ship2_name, ih.ship2_address2, ih.ship2_address1, ih.ship2_city, ih.ship2_state, ih.ship2_postal_code, ih.salesrep_id, 
		ih.salesrep_name, ih.period, ih.year_for_period, ih.ship_date, ih.total_amount, ih.amount_paid, ih.paid_in_full_flag, 
		ih.paid_by_check_no, ih.date_paid, ih.company_no, ih.corp_address_id, ih.year_fully_paid, ih.period_fully_paid, ih.branch_id, 
		ih.sold_to_customer_id, ih.sales_location_id, co.id, co.first_name AS Rep1st, co.last_name AS RepLast, co.salesrep, co.sales_manager_id, 
		c.salesrep_id AS CurrentSlsRep, c.class_1id AS CustType, c.class_2id AS CustGroup, c.class_3id AS ADMember, c.class_4id AS CustSlsCat, 
		m.class_id1 AS ItemBrand, m.class_id2 AS EPL, m.class_id3 AS IPTCISubCat, m.class_id4 AS PTISubCat, c.customer_name, 
		m.default_sales_discount_group AS CurrSlsDiscGrp, ih.po_no, x.their_item_id, m.generic_item_desc,ih.invoice_period,
		t.territory_desc
FROM	dbo.inv_mast m
		RIGHT OUTER JOIN
        dbo.invoice_line il
		ON m.inv_mast_uid = il.inv_mast_uid 
		FULL OUTER JOIN customer c
		FULL OUTER JOIN invoice_hdr ih
		LEFT OUTER JOIN contacts co
		ON ih.salesrep_id = co.id ON c.customer_id = ih.sold_to_customer_id ON il.invoice_no = ih.invoice_no
		Left join inv_xref x
		ON m.inv_mast_uid = x.inv_mast_uid and x.customer_id = 34129
		left join dbo.territory_x_customer txc
		on c.customer_id = txc.customer_id and row_status_flag = 704
		left join dbo.territory t
		on t.territory_uid = txc.territory_uid
		--where il.invoice_no = '113394'--branch_id = 300 and year_fully_paid = 2022
		
/*
go
grant select on object::A_Invoice_line_with_hdr_data_Base to p21_application_role
grant select on object::A_Invoice_line_with_hdr_data_Base to PxxiUser
grant select on object::A_Invoice_line_with_hdr_data_Base to [PTIDOM\P21Users]
*/