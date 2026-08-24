select customer_id, corp_address_id, customer_name
from customer c
join address a
on c.customer_id = a.id
where c.delete_flag = 'N' and a.delete_flag = 'N' and customer_name not like '%INACTIVE%'  and customer_name not like '%CLOSED%'  and customer_name not like '%DUPLICATE%'  and customer_name not like '%DO NOT USE%'
