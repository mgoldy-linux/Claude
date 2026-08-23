-- Get IBT Address
select a.name[IBT_Branch_Name],phys_address1,default_branch_id[PTI_Default_Branch],a.phys_postal_code,customer_id,customer_id[ShipTo_ID]
from customer c	
join address a
on c.customer_id = a.id
where class_3id = 'IBT'  and c.delete_flag = 'N' --and phys_postal_code = '55114' -- and phys_address1 like '%Route%' --and a.name not like '%Bill To'

-- Check for Primary Contact
select *
from contacts
where address_id = 33391

select *
from contacts
where id = 15238

select * 
from oe_hdr
where customer_id = 33391