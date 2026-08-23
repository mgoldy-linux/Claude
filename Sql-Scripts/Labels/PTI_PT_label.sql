select p.pick_ticket_no,m.upc_or_ean_id,item_id,item_desc,format(qty_ordered,'N0')[Qty2Print],h.order_no
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
where h.location_id = 100 and h.date_created  > DATEADD(DAY,-100,GetDate()) and l.delete_flag = 'N' and l.detail_type = 0
order by pick_ticket_no desc

select pick_ticket_no, order_no
from oe_pick_ticket
where pick_ticket_no = 2131290

select inv_mast_uid, qty_ordered,customer_part_number,assembly,delete_flag,disposition,parent_oe_line_uid,detail_type,order_no
from oe_line
where order_no in (1155625,1158930) and delete_flag = 'N'

select assembly, customer_part_number, order_no
from oe_line
where delete_flag = 'N' and source_loc_id = 100 and order_no = 1158930
order by order_no desc,line_no

