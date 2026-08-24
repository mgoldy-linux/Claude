select ship_to_id,a.name,a.phys_address1,a.phys_city,a.phys_state,a.phys_postal_code
from ship_to s
join address a
on s.ship_to_id = a.id
where customer_id = 13953
order by phys_address1