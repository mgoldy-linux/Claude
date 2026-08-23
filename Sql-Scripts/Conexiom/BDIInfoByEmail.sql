/*
  20200702 - fields need to match Customer ID/ShipTo ID/Contact ID probably in address and shipto tables
 */

with getcontacts(email_address,[Location ID],[Contact ID],[Customer ID],address_name,first_name,last_name)
as
(
select lower(email_address),cu.default_branch_id,id,address_id,address_name,first_name,last_name
from contacts ct
join customer cu
on ct.address_id = cu.customer_id
where email_address like '%@BDI-USA%' and cu.default_branch_id = 300
)
select distinct a.phys_address1[Address],Left(a.phys_postal_code,5)[ZipCode], gc.email_address,[Location ID],[Customer ID],[Customer ID][ShipTo ID],[Contact ID]
from getcontacts gc
join address a
on gc.[Customer ID] = a.id
order by ZipCode


