select h.order_no, line_no, qty_ordered,p.pick_ticket_no,p.invoice_no,p.tracking_no
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join oe_pick_ticket p
on h.order_no = p.order_no
where h.location_id = 200 and qty_ordered > 100000 and p.tracking_no not like '%can%'
order by order_date desc