select c.customer_id,default_branch_id,customer_name,ship_to_id,a.name,a.phys_address1,a.phys_city,a.phys_state,a.phys_postal_code
from customer c
join ship_to s
on c.customer_id = s.ship_to_id
join address a
on s.ship_to_id = a.id
where c.customer_name not like '%CLOSED%' and c.customer_name not like '%DUPLICATE%' and c.customer_name not like '%INACTIVE%'