select a.*
from ship_to s
join address a
on s.ship_to_id = a.id
where ship_to_id = 32102

select *
from address 
where name = 'SWANSON HEALTH PRODUCTS'

select *
from ship_to
where ship_to_id = 13877

select *
from oe_hdr
where customer_id = 32102