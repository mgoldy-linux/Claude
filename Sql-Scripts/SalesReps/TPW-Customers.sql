select customer_id,default_branch_id,customer_name,a.mail_address1,a.mail_address2,a.mail_city,a.mail_state,a.mail_postal_code,a.mail_country
from customer c
join address a
on c.customer_id = a.id
where salesrep_id = 18353
order by customer_name