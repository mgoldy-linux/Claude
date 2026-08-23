select customer_id, count(ship_to_id)[NumOfShip2s]
from Ship_to
group by customer_id 
order by NumOfShip2s desc