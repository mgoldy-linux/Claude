select p.order_no,p.tracking_no
from customer c
join oe_hdr h
on c.customer_id = h.customer_id 
join oe_pick_ticket p
on h.order_no = p.order_no
where web_enabled_flag = 'Y' and order_date between '2023-08-01' and '2023-08-10'