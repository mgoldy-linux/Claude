/*
	c.class_2id = 'Kaman'
*/

select a.phys_postal_code[Zip_Code],a.phys_city[City],a.phys_address1[Street_addr], customer_name[Customer_Name],c.default_branch_id[Branch ID],c.customer_id,ship_to_id,co.id,co.first_name,co.last_name,co.email_address 
from dbo.customer c
join dbo.address a
on c.customer_id = a.id
join dbo.contacts co
on c.customer_id = co.address_id
join dbo.ship_to sh
on c.customer_id = sh.customer_id and c.default_branch_id = sh.default_branch
where c.class_2id = 'Kaman'  and c.delete_flag = 'N'
order by phys_postal_code