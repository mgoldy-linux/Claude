select h.order_no, po_no,l.customer_part_number,l.inv_mast_uid
from oe_hdr h
JOIN oe_line l
on h.order_no = l.order_no
where customer_id = 12766 and projected_order = 'Y' and completed = 'N' and h.cancel_flag = 'N'
order by customer_part_number

select customer_id, count(order_no)
from oe_hdr
where  projected_order = 'Y' and completed = 'N' and cancel_flag = 'N'
group by customer_id