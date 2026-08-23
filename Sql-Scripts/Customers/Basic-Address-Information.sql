-- for MM LI 05/11/2022

Use P21;
--Use Play2;

select customer_id,customer_name,corp_address_id,mail_address1,mail_address2,mail_address3,mail_city,mail_state,mail_postal_code,central_phone_number,legacy_id,default_branch_id--,c.date_last_modified,c.last_maintained_by
from customer c
join address a
on c.customer_id = a.id
where c.delete_flag = 'N' and a.delete_flag = 'N' and customer_name not like '%INACTIVE%'  and customer_name not like '%CLOSED%'  and customer_name not like '%DUPLICATE%'  and customer_name not like '%DO NOT USE%'
--order by c.date_last_modified desc

--Default Branch ID	Customer ID	Customer Name	Phys Address 1	Phys Address 2	Phys City	Phys State	Sales Manager	Sales Rep ID (Cust)	Sales Rep Name (Cust),Class (Cust) 2,	Class (Cust) 4
Use P21;
--Use Play2;
with firstRound(default_branch_id,customer_id,customer_name,phys_address1,phys_address2,phys_city,phys_state,sales_manager_id,sales_rep_name,salesrep_id,class_2id,class_4id)
as
(
	select  c.default_branch_id,customer_id,customer_name,phys_address1,phys_address2,phys_city,phys_state,co.sales_manager_id,(co.first_name +  ' ' + co.last_name)[Sales Rep Name],c.salesrep_id,c.class_2id,c.class_4id
	from customer c
	join address a
	on c.customer_id = a.id
	join contacts co
	on c.salesrep_id = co.id
	where c.delete_flag = 'N' and a.delete_flag = 'N' 
)
select fR.default_branch_id,customer_id,customer_name,phys_address1,phys_address2,phys_city,phys_state,(co2.first_name +  ' ' + co2.last_name)[sales manager],sales_rep_name,salesrep_id,fR.class_2id,fR.class_4id
from firstRound fR
left join contacts co2
on fr.sales_manager_id = co2.id 
--order by c.date_last_modified desc


-- just legacy id and customer_id
select c.customer_id,c.legacy_id,u.legacy_customer_id,c.customer_name,c.default_branch_id --,c.date_last_modified,c.last_maintained_by
from dbo.customer c
left join dbo.customer_ud u
on c.customer_id = u.customer_id
where c.delete_flag = 'N' 

-- find legacy BL & ABT
select customer.customer_id, customer.customer_name, customer_ud.legacy_company_id, customer_ud.legacy_customer_id 
from customer join customer_ud 
on customer.customer_id = customer_ud.customer_id and customer.company_id = customer_ud.company_id
where legacy_company_id is not null
