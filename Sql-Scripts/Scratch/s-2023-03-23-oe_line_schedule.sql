select top 50 *
from oe_line_schedule
where order_no in (1298609, 1417479)

select top 50 *
from oe_hdr
where order_no in (1298609, 1417479)

select top 50 *
from oe_line
where order_no in (1298609, 1417479)

update dbo.oe_line_schedule
set expedite_type = 'Day(s)', pick_type = 'Day(s)'
where order_no = 1417479


select *
from dbo.oe_line_schedule
where last_maintained_by = 'mgoldyn-sql'

select top 50 *
from dbo.oe_line_schedule
order by date_created desc