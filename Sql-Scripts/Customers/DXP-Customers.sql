Select customer_name, delete_flag,customer_id
from customer 
where customer_name like 'DXP%' and delete_flag = 'N'

select c.customer_id, customer_name, cr.salesrep_id, primary_salesrep_flag,(co.first_name + ' ' + co.last_name)[sr_name], c.default_branch_id,a.phys_address1,phys_address2,a.phys_city,a.phys_state,a.phys_postal_code,a.phys_country
from customer c
left join customer_salesrep cr
on c.customer_id = cr.customer_id
left join contacts co
on co.id = cr.salesrep_id
join dbo.address a
on a.id = c.customer_id
where c.delete_flag = 'N' and co.delete_flag = 'N' and customer_name like 'DXP%'
order by customer_id -- customer_id