/*
	 05/09/23 - see keep for history
*/
use p21;
select  legacy_id,*
from customer
where customer_id = 48297

select legacy_customer_id,*
from customer_ud
where customer_id = 48297

select *
from customer_ud
where customer_id = 48297

update customer 
set legacy_id = 'MICA62'
where customer_id = 115020

update customer_ud 
set legacy_customer_id = 'MICA62'
where customer_id = 115020

select  legacy_id,*
from customer
where customer_id = 115020