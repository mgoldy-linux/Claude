-- 06/27/23 - NSK by Pick-Ticket
--use P21Play;
use P21;

if OBJECT_ID ('Bar_NSK_Pick_Ticket_15_Labels_VW', 'V') is not null
drop view Bar_NSK_Pick_Ticket_15_Labels_VW;
go

create view [dbo].[Bar_NSK_Pick_Ticket_15_Labels_VW] AS

select p.pick_ticket_no,item_id[SIMG],item_desc,format(print_quantity,'N0')[Qty2Print]
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

go 

grant select on object::Bar_NSK_Pick_Ticket_15_Labels_VW to p21_application_role
grant select on object::Bar_NSK_Pick_Ticket_15_Labels_VW to PxxiUser
grant select on object::Bar_NSK_Pick_Ticket_15_Labels_VW to [PTIDOM\P21Users]

