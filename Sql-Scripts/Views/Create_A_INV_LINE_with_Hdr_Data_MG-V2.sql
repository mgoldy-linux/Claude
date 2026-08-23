/*
	02/13/2023 - changes requested by lisa - requested name A_INV_LINE_with_Hdr_Data_MG
	R2 - remove branch 400 and all items not starting with 2
	R3 - email from Lisa 02/16/23, R4 - verbal - add item_id back in, r5 - add territories & new item class, R5 add back in item_desc, left join customer_territories table, R6 add in missing territories
	R7 - add gl sales il.gl_revenue_account_no, R* - salesrep breakdown, R8 - add sub brand (Real class_id1), select salesrep by Brand, R9 - add on phy states too
*/

use Play2;
--use P21Play;
--use P21;
/*
if OBJECT_ID ('A_INV_LINE_with_Hdr_Data_MG', 'V') is not null
drop view A_INV_LINE_with_Hdr_Data_MG;
go
create view [dbo].[A_INV_LINE_with_Hdr_Data_MG] AS
*/

SELECT	m.item_id,il.item_desc,ih.branch_id,ih.year_for_period,ih.period,il.invoice_no,il.extended_price[Sales], il.gl_cogs,il.gl_revenue_account_no,c.class_1id[CustType],c.class_2id[CustGroup],c.class_3id[ADMember],c.class_4id[CustSlsCat],
case m.class_id1 
when 'IPTCI' then 'IPTCI'
when 'LMS' then 'LMS'
when 'PTI' then 'PTI'
when 'SST' then 'SST'
when 'TRITAN' then 'TRITAN'
when 'USAR' then 'ROLLERS'
else 'OTHER'
end[ItemBrand],m.class_id1[SubBrand],
		ih.customer_id[customer_id_on_order],c.customer_name,a.phys_city
	,a.phys_state,a.phys_postal_code,il.other_charge_item,tsr.Territory,
case m.class_id1
when 'PTI' then PTI
when 'IPTCI' then IPTCI
when 'TRITAN' then TRITAN
else OTHER
end[SalesRep],SMgr_Primary,SMgr_Secondary
		/*ih.sales_location_id,il.qty_shipped, il.item_desc, il.unit_price, 
		 il.gl_revenue_account_no, il.gl_inventory, il.date_created, 
		il.order_no, il.cogs_amount, 
		il.line_no, 
		ih.order_date, ih.invoice_date, ih.customer_id, 
		ih.ship2_name, ih.ship2_address2, ih.ship2_address1, ih.ship2_city, ih.ship2_state, ih.ship2_postal_code, ih.salesrep_id, 
		ih.salesrep_name, ih.year_fully_paid, ih.period_fully_paid, 
		ih.sold_to_customer_id,co.sales_manager_id, 
		 
		m.default_product_group*/
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
		left join Customer_SR_Territories tsr
		on c.customer_id = tsr.customer_id_on_order 
Where  ih.branch_id < 401 and year_for_period in (2022,2023) and il.item_desc not like '%rebate%' --and il.invoice_no = '3221026'--and a.phys_country = 'CN' --and default_product_group is not null--and ih.order_no = '1349682' --and sales_location_id is null dateadd(day,datediff(day,730,GETDATE()),0) ih.order_date > '2021-06-30'and
--order by sales_location_id  
/*
go 

grant select,update,references on object::A_INV_LINE_with_Hdr_Data_MG to admin
grant select,update,references on object::A_INV_LINE_with_Hdr_Data_MG to crystal
grant select,update,references on object::A_INV_LINE_with_Hdr_Data_MG to [PTIDOM\P21Users]
*/