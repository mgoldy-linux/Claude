select c.customer_id,customer_name, sr.salesrep_id, phys_state
from dbo.customer c
join dbo.customer_salesrep sr
on c.customer_id = sr.customer_id
join dbo.address a
on a.id = c.customer_id
where c.salesrep_id in (1024,1027,1035) and c.delete_flag = 'N'