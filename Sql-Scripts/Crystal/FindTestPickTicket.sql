select p.pick_ticket_no,l.source_loc_id,p.order_no
from oe_line l
join oe_pick_ticket p
on l.order_no = p.order_no
where inv_mast_uid = 8234;

select inv_mast_uid
from inv_mast
where item_id = 'CL211-35'
