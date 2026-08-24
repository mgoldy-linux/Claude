--use P21Play;
use P21;
/*
if OBJECT_ID ('BAR_100_Test_PT_Label_VW', 'V') is not null
drop view BAR_100_Test_PT_Label_VW;
go

create view [dbo].[BAR_100_Test_PT_Label_VW] AS
*/


select p.pick_ticket_no,m.upc_or_ean_id,item_id,item_desc,format(qty_ordered,'N0')[Qty2Print],h.order_no,default_product_group,h.customer_id,their_item_id,p.printed_flag
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
left join inv_xref x
on h.customer_id = x.customer_id and m.inv_mast_uid = x.inv_mast_uid
where h.location_id = 100 and h.date_created  > DATEADD(DAY,-1,GetDate()) and l.delete_flag = 'N' and l.detail_type = 0 and default_product_group != 'OTHERCHG' and h.projected_order = 'N'

/*
go 

grant select,update,references on object::BAR_100_Test_PT_Label_VW to admin
grant select,update,references on object::BAR_100_Test_PT_Label_VW to crystal
grant select,update,references on object::BAR_100_Test_PT_Label_VW to [PTIDOM\P21Users]
*/