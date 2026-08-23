select projected_order, taker, order_date,last_maintained_by
from oe_hdr
where order_no = 1098418

update oe_hdr
set projected_order = 'Y'
where order_no = 1098418

select projected_order, taker, order_date,last_maintained_by
from oe_hdr
where order_no = 1098418
