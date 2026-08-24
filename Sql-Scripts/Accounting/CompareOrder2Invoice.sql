select parent_oe_line_uid,*
from oe_line
where order_no = 1000223


select *
from invoice_line
where invoice_no = '3000043'

select distinct detail_type
from oe_line