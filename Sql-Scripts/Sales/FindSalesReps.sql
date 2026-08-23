/*
	Created 2020-01-07
*/

-- find sales reps
select id, first_name, last_name
from contacts 
where salesrep = 'Y'
order by first_name

-- find all sales rep that have taken orders
select distinct salesrep_id, first_name, last_name
from oe_hdr_salesrep o
join contacts c
on  o.salesrep_id = c.id

/*
select salesrep_id,first_name,last_name
from oe_hdr_salesrep sr
join contacts c
on sr.salesrep_id = c.id
where order_number = 1026124
*/