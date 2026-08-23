-- Note must unallocate item if changing order to quote

select projected_order
from oe_hdr
where order_no =  1066161

update oe_hdr
set projected_order = 'N' where  order_no =  1066161

select projected_order
from oe_hdr
where order_no =  1066161