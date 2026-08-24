/*
	Need Customer Id,shipto Id, Contact ID
	shipTo ID = Customer ID
*/

with getBranches(IBTbranchID,IBT_Branch_Name,PTI_Default_Branch,Zip_Code,customer_id,ShipTo_ID)
as
(
	select SUBSTRING(email_address,4,2)[IBTbranchID],a.name[IBT_Branch_Name],default_branch_id[PTI_Default_Branch],left(a.phys_postal_code,5)[Zip_Code],customer_id,customer_id[ShipTo_ID]
	from customer c	
	join address a
	on c.customer_id = a.id
	where c.class_3id = 'IBT' and c.delete_flag = 'N' and a.name not like 'AD%' --and a.name not like '%Bill To'
	),
getContacts
as
(
	select distinct IBTbranchID,IBT_Branch_Name,PTI_Default_Branch,Zip_Code,gb.customer_id,ShipTo_ID,contact_id
	from getBranches gb
	join oe_hdr h
	on gb.customer_id = h.customer_id
	where contact_id is not null
	)
select IBTbranchID,IBT_Branch_Name,PTI_Default_Branch,Zip_Code,customer_id,ShipTo_ID,contact_id,first_name,last_name
from getContacts gc
join contacts co
on gc.contact_id = co.id
--where customer_id = 11558
order by Zip_Code



