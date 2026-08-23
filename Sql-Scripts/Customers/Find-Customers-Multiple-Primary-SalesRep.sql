-- get a count of number salesrep
select cs.customer_id,c.customer_name,count(primary_salesrep_flag)[NumOfSalesRep],c.delete_flag
from customer_salesrep cs
join customer c
on cs.customer_id = c.customer_id
where primary_salesrep_flag = 'Y'
group by cs.customer_id,c.customer_name,c.delete_flag
Having count(primary_salesrep_flag) > 1
order by NumOfSalesRep desc

with getids 
as
(
	select cs.customer_id
	from customer_salesrep cs
	where primary_salesrep_flag = 'Y'
	group by cs.customer_id
	Having count(primary_salesrep_flag) > 1
)
select g.customer_id, cs2.salesrep_id,c.first_name,c.last_name
from getids g
join customer_salesrep cs2
on g.customer_id = cs2.customer_id
join contacts c
on c.id = cs2.salesrep_id
order by g.customer_id
--join customer c
--on g.customer_id = cs2.customer_id and cs2.salesrep_id = c.salesrep_id
--order by NumOfSalesRep desc