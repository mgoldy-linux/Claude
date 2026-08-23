/*
	08/24/2020 - query to create spreadsheet of DXP branches
	indentfy branches by zipcode
	columns: (input) zipcode, branch city, (output) PTI Default branch, customer_id, shipTo_id, contact_id
	need to manualy remove extra contacts
*/

with getBranches(Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID)
as
(
	select left(a.phys_postal_code,5),a.phys_city,a.phys_address1, customer_name,default_branch_id,customer_id,customer_id 
	from customer c
	join address a
	on c.customer_id = a.id
	where class_2id = 'DXP' and customer_name not like '%Bill TO%' and customer_name != 'DXP - LIN'
)
select Zip_Code,City,Street_Addr,customer_name,PTI_Default_Branch,customer_id,shipTo_ID,co.id,co.first_name,co.last_name
from getBranches gb
join contacts co
on gb.customer_id = co.address_id
--where gb.PTI_Default_Branch = 300
--where co.first_name = 'Primary'
order by Zip_Code