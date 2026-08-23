select c.customer_id,customer_name,default_branch_id,c.salesrep_id,cs.salesrep_id[customer-sr-tab],class_4id,class_2id,phys_city,phys_state,phys_country
from dbo.address a
join dbo.customer c
on a.id = c.customer_id
left join dbo.customer_salesrep cs
on c.customer_id = cs.customer_id
where phys_country in ('CA','CANADA') and cs.row_status_flag = 704

select distinct phys_country
from address
order by phys_country

select c.customer_id,customer_name,default_branch_id,c.salesrep_id,cs.salesrep_id[customer-sr-tab],class_4id,class_2id, phys_city,phys_state,phys_country
from dbo.address a
join dbo.customer c
on a.id = c.customer_id
left join dbo.customer_salesrep cs
on c.customer_id = cs.customer_id
where phys_state in ('AB','BC','MB','NB','NF','NL','NS','NT','NU','ON','ONTARIO','PE','PQ','QC','SK','YT') and cs.row_status_flag = 704
order by phys_state,phys_country

select distinct phys_state
from address
where phys_country in ('CA','CANADA')
order by phys_state

select *
from ship_to_salesrep
where ship_to_id = 96132