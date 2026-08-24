-- 05/31/22 email from DWALD, requesting delete of order

/*
select *
from oe_hdr
where last_maintained_by = 'DWALD' and po_no = '86946'
order by date_created desc

update oe_hdr
set delete_flag = 'Y'
where order_no = 'pacmac'

select delete_flag
from oe_hdr
where last_maintained_by = 'DWALD' and po_no = '86946'
order by date_created desc

-- need to update order lines to
select *
from oe_line
where order_no = 'pacmac'

update oe_line
set delete_flag = 'Y'
where order_no = 'pacmac'

select *
from oe_line
where order_no = 'pacmac'

-- per Marlenne 09/21/2022
select *
from oe_hdr
where order_no = 1328199

update oe_hdr
set delete_flag = 'Y'
where order_no = 1328199

select delete_flag
from oe_hdr
where order_no = 1328199

-- need to update order lines to
select *
from oe_line
where order_no = 1328199

update oe_line
set delete_flag = 'Y'
where order_no = 1328199

select delete_flag, *
from oe_line
where order_no = 1328199
*/
-- per Marlenne 02/01/2024  - Check complete flag is off = 'N'
select *
from oe_hdr
where order_no = 1613739

update oe_hdr
set delete_flag = 'Y'
where order_no = 1613739

select delete_flag
from oe_hdr
where order_no = 1613739

select *
from oe_line
where order_no = 1613739

update oe_line
set delete_flag = 'Y'
where order_no = 1613739

select delete_flag, line_no
from oe_line
where order_no = 1613739