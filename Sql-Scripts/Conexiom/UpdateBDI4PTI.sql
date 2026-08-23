/*
	08/31/2020 - Update to BDI to include PTI locations

*/
-- US and Mexico
with getBranches(Address,Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID)
as
(
	select a.phys_address1,left(a.phys_postal_code,5),a.phys_city,a.phys_address1, customer_name,default_branch_id,customer_id,customer_id 
	from customer c
	join address a
	on c.customer_id = a.id
	where class_2id in ('BDI','BDI-MS') and customer_name not like '%Closed%' 
)
select Address,Zip_Code[ZipCode],PTI_Default_Branch[Location ID],customer_id[Customer ID],shipTo_ID[ShipTo ID],co.id[Contact ID]
from getBranches gb
join contacts co
on gb.customer_id = co.address_id
where gb.PTI_Default_Branch = 100 and co.first_name = 'Primary'
order by Zip_Code


-- canada because of zip
with getBranches(Address,Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID)
as
(
	select a.phys_address1,left(a.phys_postal_code,7),a.phys_city,a.phys_address1, customer_name,default_branch_id,customer_id,customer_id 
	from customer c
	join address a
	on c.customer_id = a.id
	where class_2id = 'BDI-CAN' and customer_name not like '%Closed%' 
)
select Address,Zip_Code[ZipCode],PTI_Default_Branch[Location ID],customer_id[Customer ID],shipTo_ID[ShipTo ID],co.id[Contact ID]
from getBranches gb
join contacts co
on gb.customer_id = co.address_id
where gb.PTI_Default_Branch = 100 and co.first_name = 'Primary'
order by Zip_Code
