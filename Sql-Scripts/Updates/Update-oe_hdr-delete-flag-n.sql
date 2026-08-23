use P21;

select delete_flag
from oe_hdr
where order_no = 1419096

select delete_flag,*
from oe_line
where order_no = 1419096

update oe_hdr
set delete_flag = 'N'
where order_no = 1419096

update oe_line
set delete_flag = 'N'
where order_no = 1419096 and line_no = 1

select delete_flag
from oe_hdr
where order_no = 1419096

select delete_flag,*
from oe_line
where order_no = 1419096
