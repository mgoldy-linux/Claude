select distinct x.customer_id,c.customer_name
from dbo.inv_xref x
join dbo.customer c
on x.customer_id = c.customer_id
--where customer_name like '%MSC%'

