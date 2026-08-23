--"Customer(s) missing default branch ID"

use P21Local2020;

select distinct c.customer_id,c.customer_name, c.date_created,s.default_branch[ShipToDefaultID],default_branch_id[CustomerDefaultID],c.last_maintained_by
from customer c
join ship_to s
on c.customer_id = s.customer_id
where c.default_branch_id is null and c.delete_flag = 'N'
order by customer_id desc

-- $qryQA = @"
        select Count(id)[aid]
        from address
        where date_last_modified BETWEEN DATEADD(Day,-1,GETDATE()) AND GETDATE()

select distinct top 7 c.customer_id,c.customer_name, c.date_created,s.default_branch[ShipToDefaultID],default_branch_id[CustomerDefaultID],c.last_maintained_by
from customer c
join ship_to s
on c.customer_id = s.customer_id
where c.default_branch_id =  100 and c.delete_flag = 'N'
order by customer_id desc

select top 7 id, name, mail_address1,mail_address2,mail_city,mail_state,mail_postal_code,mail_country,phys_country,ups_code,shipping_address,last_maintained_by,replace(convert(varchar(12), date_created, 110),'-','/') as [Date]
from address 
order by id desc

select top 37 convert(int,c.id)[id], address_id,first_name,last_name, c.class_5id,cu.web_enabled_flag, c.email_address,replace(convert(varchar(12), c.date_last_modified, 110),'-','/') as [Mod],a.phys_country,a.mail_country, replace(convert(varchar(12), c.date_created, 110),'-','/') as [Create],c.last_maintained_by
from contacts c
join customer cu
on c.address_id = cu.customer_id
join address a
on cu.customer_id = a.id
order by id desc