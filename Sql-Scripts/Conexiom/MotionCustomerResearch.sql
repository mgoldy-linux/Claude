-- Need to get 300 customers id first, then contacts and address

select *
from address 
where phys_state = 'AK'

select *
from customer
where customer_id = 12336 or customer_id = 13989