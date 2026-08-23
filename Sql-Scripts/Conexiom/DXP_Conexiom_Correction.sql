-- fix DXP 
-- add 402-731-3480 for customer id 14960
select c.default_branch_id,customer_name,a.phys_address1,central_phone_number[phone1], c.customer_id,ship_to_id,co.id,co.first_name,co.last_name,co.email_address
from dbo.customer c
join dbo.address a
on c.customer_id = a.id
join dbo.contacts co
on c.customer_id = co.address_id
join dbo.ship_to sh
on c.customer_id = sh.customer_id and c.default_branch_id = sh.default_branch
where c.class_2id in ('DXP')  and c.delete_flag = 'N'-- /*and central_phone_number like '%937%'--*/ and default_branch_id = 300 and phys_postal_code like '45365%'
order by phys_postal_code

select *
from contacts
where last_name = 'Jacobs' and first_name = 'Chad'

select *
from contacts
where address_id = 14960	

select a.name,c.customer_name
from customer c
join address a
on c.customer_id = a.id
where customer_id = 15679

select *
from address 
where name like 'Schwans%'

