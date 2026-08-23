--use P21Play;

select *
from dbo.oe_line_schedule
where last_maintained_by = 'mgoldyn-sql'

update dbo.oe_line_schedule
set expedite_type = 'Day(s)', pick_type = 'Day(s)'
where last_maintained_by = 'mgoldyn-sql'

select *
from dbo.oe_line_schedule
where last_maintained_by = 'mgoldyn-sql'

select order_no, line_no
from dbo.oe_line_schedule
where expedite_type = 'Days(s)'