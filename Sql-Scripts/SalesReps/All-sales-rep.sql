-- 06/29/2022 all customer , MM said different from Webquery

select c.customer_id, customer_name, cr.salesrep_id, primary_salesrep_flag,(co.first_name + ' ' + co.last_name)[sr_name]
from customer c
left join customer_salesrep cr
on c.customer_id = cr.customer_id
left join contacts co
on co.id = cr.salesrep_id
where c.delete_flag = 'N' and co.delete_flag = 'N'  --and sr_name like '%southw%'
order by sr_name -- customer_id
 
with get_SRs (SR_ID,sr_name,sales_manager_id)
as
(
	select distinct cr.salesrep_id,(co.first_name + ' ' + co.last_name), sales_manager_id
	from customer c
	left join customer_salesrep cr
	on c.customer_id = cr.customer_id
	left join contacts co
	on co.id = cr.salesrep_id
	where c.delete_flag = 'N' and co.delete_flag = 'N'
	)
select SR_ID,sr_name,c.last_name[mgr_last_name],g.sales_manager_id
from get_SRs g
left join dbo.contacts c
on g.sales_manager_id = c.id 
--where g.sales_manager_id = 1008
order by g.SR_ID



select contact_role_uid,id, first_name,last_name,email_address, sales_manager_id
from dbo.contacts
where salesrep = 'Y' and delete_flag = 'N' and email_address is not null
order by id desc

select *
from contacts 
where id between 34440 and 34450

select *
from contacts 
where first_name = 'Southwest' or last_name = 'CPTS'


select distinct salesrep_id

from customer_salesrep

-- ID 1004 - PTI Inhouse
select c.customer_id, customer_name, a.phys_address1,a.phys_address2,a.phys_city,a.phys_state,a.phys_postal_code,c.salesrep_id[Customer Info tab],cr.salesrep_id[SalesRep Tab], primary_salesrep_flag,(co.first_name + ' ' + co.last_name)[sr_name], c.class_1id,c.class_2id,c.class_4id
from dbo.customer c
left join dbo.customer_salesrep cr
on c.customer_id = cr.customer_id
left join dbo.contacts co
on co.id = cr.salesrep_id
join address a
on c.customer_id = a.id
where c.delete_flag = 'N' and co.delete_flag = 'N'and (c.salesrep_id = 1004 or cr.salesrep_id = 1004)
order by customer_id 
 

 select count(*)[NumOf]
 from customer
 where salesrep_id = 1004

 select *
 from customer_salesrep
  where salesrep_id = 1004  and customer_id = 10348
