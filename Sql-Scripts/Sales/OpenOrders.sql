select s.salesrep_id,count(order_no)[Open orders]
from oe_hdr h
join oe_hdr_salesrep s
on h.order_no = s.order_number
where approved = 'N' and cancel_flag = 'N' and h.delete_flag = 'N' and projected_order = 'N'
group by salesrep_id
order by [Open orders] desc

select order_no, customer_id,ship2_name,taker,order_date
from oe_hdr h
join oe_hdr_salesrep s
on h.order_no = s.order_number
where approved = 'N' and cancel_flag = 'N' and h.delete_flag = 'N' and salesrep_id = 1021 and rma_flag = 'N'  and projected_order = 'N'