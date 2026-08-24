select order_no,po_no, ship2_name, order_date,requested_date, datediff(day,order_date,requested_date)[TurnAround]
from dbo.oe_hdr
where customer_id = 55932 and completed = 'N' and delete_flag = 'N' and cancel_flag = 'N' and projected_order = 'N'
order by requested_date desc 