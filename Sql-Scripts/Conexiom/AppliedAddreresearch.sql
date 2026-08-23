select *
from oe_hdr
where po_no = '4507718085'

select *
from address
where id = 14448

select default_branch_id,*
from customer
where customer_id =  14448

select *
from contacts
where address_id= 14448

select *
from address
where name like 'APPLIED%'