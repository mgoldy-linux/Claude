Select *
from Bar_NSK_Pick_Ticket_15_Labels_VW
where pick_ticket_no = 2516257

select p.pick_ticket_no,item_id[SIMG],item_desc,format(print_quantity,'N0')[Qty2Print]
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
join dbo.oe_pick_ticket_detail opt
on p.pick_ticket_no = opt.pick_ticket_no and opt.oe_line_no = l.line_no
where  h.completed = 'N' and p.delete_flag = 'N' and h.delete_flag = 'N' and l.delete_flag = 'N' and default_product_group not in ('OTHERCHG','D1') and h.rma_flag = 'N' and p.invoice_no is null and  opt.pick_ticket_no = 2516257

select *
from oe_pick_ticket_detail
where pick_ticket_no = 2516257


Select *
from Bar_PT_Solve_VW_lmit_1
where pick_ticket_no = 2516257

use P21Dev3;
select *
from modification
