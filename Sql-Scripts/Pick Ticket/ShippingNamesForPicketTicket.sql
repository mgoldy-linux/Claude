select distinct o.carrier_id, name
from oe_hdr o
join address a 
on o.carrier_id = a.id
order by name
--where order_no = 1011574

-- find carriers
select name, address_id_string
from  address
where carrier_flag = 'Y'
order by name


