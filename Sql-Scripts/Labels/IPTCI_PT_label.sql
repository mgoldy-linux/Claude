
select p.pick_ticket_no,item_id,item_desc,m.extended_desc,format(qty_ordered,'N0')[Qty2Print],h.order_no
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join oe_pick_ticket p
on h.order_no = p.order_no
where h.location_id = 300 and assembly = 'n' and h.date_created  > DATEADD(DAY,-100,GetDate())
order by h.date_created desc