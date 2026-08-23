/*
	02/13/2023 - changes requested by lisa - requested name A_INV_LINE_with_Hdr_Data_MG
	R2 - remove branch 400 and all items not starting with 2
*/

--use Play2;
--use P21Play;
use P21;
/*
if OBJECT_ID ('A_INV_LINE_with_Hdr_Data_MG', 'V') is not null
drop view A_INV_LINE_with_Hdr_Data_MG;
go
create view [dbo].[A_INV_LINE_with_Hdr_Data_MG] AS
*/

SELECT	ih.customer_id[order_customer_id],c.customer_name,a.phys_city,a.phys_state,a.phys_postal_code,il.invoice_no,ih.sales_location_id,il.qty_shipped,m.item_id, il.item_desc, il.unit_price, 
		il.extended_price, il.gl_revenue_account_no, il.gl_cogs, il.gl_inventory, il.date_created, 
		il.order_no, il.cogs_amount, 
		il.line_no,il.other_charge_item, 
		ih.order_date, ih.invoice_date, ih.customer_id, 
		ih.ship2_name, ih.ship2_address2, ih.ship2_address1, ih.ship2_city, ih.ship2_state, ih.ship2_postal_code, ih.salesrep_id, 
		ih.salesrep_name, ih.period, ih.year_for_period,ih.year_fully_paid, ih.period_fully_paid, ih.branch_id, 
		ih.sold_to_customer_id,co.sales_manager_id, 
		c.class_1id AS CustType, c.class_2id AS CustGroup, c.class_3id AS ADMember, c.class_4id AS CustSlsCat, 
		m.class_id1 AS ItemBrand,m.default_product_group
FROM	dbo.inv_mast m
		RIGHT OUTER JOIN  dbo.invoice_line il
		ON m.inv_mast_uid = il.inv_mast_uid 
		FULL OUTER JOIN dbo.customer c
		FULL OUTER JOIN dbo.invoice_hdr ih
		LEFT OUTER JOIN dbo.contacts  co
		ON ih.salesrep_id = co.id 
		ON c.customer_id = ih.sold_to_customer_id ON il.invoice_no = ih.invoice_no 
		join dbo.address a
		on c.customer_id = a.id
Where ih.order_date > '2021-06-30' --and default_product_group is not null--and ih.order_no = '1349682' --and sales_location_id is null dateadd(day,datediff(day,730,GETDATE()),0) 
--order by sales_location_id 

/*
go 

grant select on object::A_INV_LINE_with_Hdr_Data_MG to p21_application_role
grant select on object::A_INV_LINE_with_Hdr_Data_MG to PxxiUser
grant select on object::A_INV_LINE_with_Hdr_Data_MG to [PTIDOM\P21Users]
*/