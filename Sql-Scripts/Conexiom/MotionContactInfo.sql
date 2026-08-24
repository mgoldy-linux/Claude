/*
	07/10/2020 - need to match zipcode to branch id. Branch ID format is in two-letter state abbreviation follow by two digits
*/

with getcontacts(direct_phone,[Location ID],[Contact ID],[Customer ID],address_name,first_name,last_name)
as
(
select direct_phone,cu.default_branch_id,id,address_id,address_name,first_name,last_name
from contacts ct
join customer cu
on ct.address_id = cu.customer_id
where address_name like 'motion%'/*and cu.default_branch_id = 300*/ and first_name = 'Primary'  and cu.delete_flag = 'N'
)
select distinct a.phys_address1[Address],Left(a.phys_postal_code,5)[ZipCode], gc.direct_phone,[Location ID],[Customer ID],[Customer ID][ShipTo ID],[Contact ID]
from getcontacts gc
join address a
on gc.[Customer ID] = a.id
order by gc.[Customer ID] 
--order by ZipCode


select customer_name,*
from customer c
where class_2id = 'MOTION' and customer_name like '%RUSS%'
order by c.customer_name

Select *
from oe_hdr 
where po_no = 'AR57-00198162'

select *
from oe_hdr_salesrep
where order_number = 1339704