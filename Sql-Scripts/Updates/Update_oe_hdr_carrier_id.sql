--- tested on Play 02/11/22 

use P21Play;
--use P21;

-- gives you the affective orders
select order_no
from dbo.oe_hdr 
where customer_id = 10782 and completed = 'N'

-- find the carrie id
select name, id
from address
where id in (16253,16274)

-- orders before update
select order_no, completed, h.carrier_id,a.name
from oe_hdr h
join address a
on h.carrier_id = a.id 
where customer_id = 10782 and completed = 'N'

-- update the orders
update oe_hdr
set carrier_id = 16253
where customer_id = 10782 and completed = 'N'

--orders after update
select order_no, completed, h.carrier_id,a.name
from oe_hdr h
join address a
on h.carrier_id = a.id 
where customer_id = 10782 and completed = 'N'