/*
	
	start 01/13/20 - from email
	Ideal Fields to include…
	From Customer Table: Name, Legacy ID, P21 Cust#, Rep ID,Dist or OEM, Sub Category of Distributor (AD, AIT, BDI, KIT, MI, Other, Purvis), 
	From Address Table: City, ST,  
	From Contacts Table: Rep ID Name, PTI/IPTCI is "address_Name" Region?
	Exported to CustomerListing.xlsx

*/


use P21;

With cteCustomer(customer_name,City,State,legacy_id,customer_id,salesrep_id,Customer_Type,Customer_Group,AD_Chain,class_4id)
as
(
	select customer_name,phys_city[City],phys_state[State],legacy_id,customer_id,salesrep_id,class_1id[Customer_Type],class_2id[Customer_Group],class_3id[AD Chain],class_4id
	from customer c
	join address a
	on c.customer_id = a.id
)
select customer_name,City,State,legacy_id,customer_id,salesrep_id,(first_name + ' ' + last_name)[SalesRepName],Customer_Type,Customer_Group,AD_Chain,cc.class_4id,address_name[Region],
Case 
	when sales_manager_id = 1007 then 'Michael Moonan'
	when sales_manager_id = 1008 then 'George Dib'
	when sales_manager_id = 1009 then 'Sam Hitchison'
	when sales_manager_id = 1010 then 'Ryan Linke'
	when sales_manager_id = 1011 then 'Doug Hampton'
	when sales_manager_id = 1012 then 'Brent Oman'
	else 'No Sales Manager Entered'
End AS Sales_Manager
from cteCustomer cc
join contacts co
on cc.salesrep_id = co.id
