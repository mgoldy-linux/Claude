-- use excel to highlight duplicates

select ship_to_id,a.name,a.phys_address1,a.phys_city,a.phys_state,a.phys_postal_code,central_phone_number
from ship_to s
join address a
on s.ship_to_id = a.id
where default_branch = 530
order by name