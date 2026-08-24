select *
from oe_hdr
where projected_order = 'Y' and location_id = 300 and cancel_flag = 'N' and delete_flag = 'N'
order by order_date desc