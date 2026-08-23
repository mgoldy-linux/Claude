-- locations of default branch id - company, contacts,cust_defaults,customer,location
-- not affected - location,cust_defaults, company
-- default branch data is missing from contacts

select distinct c.customer_id,c.customer_name, c.date_created,s.default_branch
from customer c
join ship_to s
on c.customer_id = s.customer_id
where c.default_branch_id is null and c.delete_flag = 'N'
order by customer_id desc

select c.customer_id,customer_name, c.date_created,default_branch_id[Customer Default],s.default_branch
from customer c
join ship_to s
on c.customer_id = s.customer_id
where c.date_created > '2020-05-28' --and c.customer_id > 26546
order by c.date_created desc