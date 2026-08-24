--use P21Sand;
use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_PT_Solve_VW_limit_1', 'V') is not null
drop view Bar_PT_Solve_VW_limit_1;
go

create view [dbo].[Bar_PT_Solve_VW_limit_1] AS
*/

select p.pick_ticket_no,h.order_no,l.line_no,m.item_id,m.item_desc,
case
	when class_id1 = 'PTI' and default_price_family_uid = 9 then 'GoldSpec'
	when class_id1 = 'PTI' and default_price_family_uid = 11 then 'NSK'
	when customer_id in (12989,12990,12991,12992,12993) then 'NSK'
else class_id1
end [LogoBrand],default_product_group,pf.price_family_id,'1'[Qty2Print]--,customer_id
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
join dbo.oe_pick_ticket_detail opt
on p.pick_ticket_no = opt.pick_ticket_no and opt.oe_line_no = l.line_no
where h.location_id = 100 and h.completed = 'N' and projected_order = 'N' and l.delete_flag = 'N' and l.detail_type = 0 and default_product_group not in ('OTHERCHG','D1') and h.rma_flag = 'N' and p.delete_flag = 'N' and p.invoice_no is null 
and l.qty_on_pick_tickets != 0 
---order by customer_id --default_product_group
go 
/*
grant select on object::Bar_PT_Solve_VW_limit_1 to p21_application_role
grant select on object::Bar_PT_Solve_VW_limit_1 to PxxiUser
grant select on object::Bar_PT_Solve_VW_limit_1 to [PTIDOM\P21Users]
*/