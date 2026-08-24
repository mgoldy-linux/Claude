/*
	Need Customer Id,shipto Id, Contact ID
	shipTo ID = Customer ID
	can't filter out A/P because sometimes only contact
*/

with getBranches(Address,Kaman_Branch_Name,PTI_Default_Branch,Zip_Code,customer_id,ShipTo_ID)
as
(
	select a.phys_address1,a.name[Kaman_Branch_Name],default_branch_id[PTI_Default_Branch],left(a.phys_postal_code,5)[Zip_Code],customer_id,customer_id[ShipTo_ID]
	from customer c	
	join address a
	on c.customer_id = a.id
	where c.class_2id = 'kaman' and c.delete_flag = 'N' and a.name not like 'AD%' --and a.name not like '%Bill To'
	),
getContacts
as
(
	select distinct Address,Kaman_Branch_Name,PTI_Default_Branch,Zip_Code,gb.customer_id,ShipTo_ID,contact_id
	from getBranches gb
	join oe_hdr h
	on gb.customer_id = h.customer_id
	where contact_id is not null
	)
select Address,Kaman_Branch_Name,Zip_Code,PTI_Default_Branch[Location_id],customer_id,ShipTo_ID,contact_id,first_name,last_name
from getContacts gc
join contacts co
on gc.contact_id = co.id
--where Zip_Code like '%46802%'
--where customer_id in (14395,12047)
order by Zip_Code



