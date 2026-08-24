select customer_id,salesrep_id
from Customer
where customer_id in (13904,15110,15133,15136,15246,16598,28848)

select sales_manager_id,*
from contacts
where id = 1038

select *
from customer_salesrep
where customer_id in (13904,15110,15133,15136,15246,16598,28848)

select *
from oe_hdr_salesrep
where salesrep_id = 1006
