Select *
from inv_loc
where location_id = 601 and qty_on_hand > 0 


select *
from location

select distinct preferred_location_id
from address
where customer = 'Y'