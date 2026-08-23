select *
from oe_pick_ticket
where pick_ticket_no = 2243418

select h.location_id, h.completed , projected_order
from oe_hdr h
where order_no = 1305701

select l.delete_flag, l.detail_type, inv_mast_uid
from oe_line l
where order_no = 1305701

select *
from inv_mast
where inv_mast_uid = 105880