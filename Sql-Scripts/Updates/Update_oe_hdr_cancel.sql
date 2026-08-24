select cancel_flag, *
from dbo.oe_hdr
where order_no in (1157650,1158569)

update dbo.oe_hdr
set cancel_flag = 'Y'
where order_no in (1157650,1158569)

select cancel_flag, *
from dbo.oe_hdr
where order_no in (1157650,1158569)