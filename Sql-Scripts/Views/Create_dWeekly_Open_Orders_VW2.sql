/*
		11/21/22 - recommendations from SR1029
*/
use P21Play;
--use P21;

/*
if OBJECT_ID ('dWeekly_Open_Orders_VW2', 'V') is not null
drop view dWeekly_Open_Orders_VW2;
go

create view [dbo].[dWeekly_Open_Orders_VW2] AS
*/
select oh.order_no, format(order_date,'MM/dd/yyyy')[order_date],po_no,a.name,m.item_id[SIMG],ol.customer_part_number,item_desc,(qty_ordered -  qty_invoiced)[QTY Remaining],qty_ordered,unit_price,extended_price, ol.disposition,salesrep_id 
from dbo.oe_hdr oh
join dbo.oe_hdr_salesrep os
on oh.order_no = os.order_number
join dbo.oe_line ol
on oh.order_no = ol.order_no
join dbo.inv_mast m
on ol.inv_mast_uid = m.inv_mast_uid 
join dbo.address a 
on oh.customer_id = a.id
where projected_order = 'N' and oh.delete_flag = 'N' and oh.cancel_flag = 'N' and oh.completed = 'N' and ol.cancel_flag = 'N' and ol.delete_flag = 'N' and ol.complete = 'N' and oh.rma_flag = 'N' and unit_price > 0 and m.other_charge_item = 'N' 
--order by order_no
/*
go 

grant select,update,references on object::dWeekly_Open_Orders_VW2 to admin
grant select,update,references on object::dWeekly_Open_Orders_VW2 to crystal
grant select,update,references on object::dWeekly_Open_Orders_VW2 to [PTIDOM\P21Users]
*/