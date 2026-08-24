/*
Cust#,Cust Name,Address1,Address2,City,State (Province),Country,Phone Number,Class 2,Class 4,SalesRep ID,SalesRep Name,Sales Manager
*/

with get_SRs ([Cust#],[Cust Name],[Address1],[Address2],[City],[State (Province)],[Country],[Phone],[Class 2],[Class 4],[SalesRep ID],[SalesRep Name],Sales_Mgr,[Bill To ID],default_branch_id)
as
(
select c.customer_id,customer_name,phys_address1,phys_address2,phys_city,phys_state,phys_country,central_phone_number,c.class_2id,c.class_4id,c.salesrep_id,(co.first_name + ' ' + co.last_name),sales_manager_id,corp_address_id,c.default_branch_id
from dbo.address a
join dbo.customer c
on a.id = c.customer_id
left join contacts co
on co.id = c.salesrep_id 
where c.delete_flag = 'N' and co.delete_flag = 'N' 
)
select [Cust#],[Cust Name],[Address1],[Address2],[City],[State (Province)],[Country],[Phone],[Class 2],[Class 4],[SalesRep ID],[SalesRep Name],(co2.first_name + ' ' + co2.last_name)[Sales Manager],t.territory_desc,[Bill To ID],gs.default_branch_id
from get_SRs gs
left join contacts co2
on gs.Sales_Mgr = co2.id
LEFT OUTER JOIN
P21Sand.dbo.territory_x_customer AS txc ON gs.[Cust#] = txc.customer_id and txc.row_status_flag = 704 
LEFT OUTER JOIN
P21Sand.dbo.territory AS t ON txc.territory_uid = t.territory_uid
/*
select *
from contacts
where id = 40391

select *
from customer
where customer_id = 10329

select *
from address
where id = 40391
*/
