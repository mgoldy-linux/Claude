select distinct top 7 c.customer_id,c.customer_name, c.date_created,s.default_branch[ShipToDefaultID],default_branch_id[CustomerDefaultID],c.last_maintained_by
from customer c
join ship_to s
on c.customer_id = s.customer_id
where c.default_branch_id =  100 and c.delete_flag = 'N'
order by customer_id desc

select top 7 id, name, mail_address1,mail_address2,mail_city,mail_state,mail_postal_code,mail_country,phys_country,ups_code,shipping_address,last_maintained_by,replace(convert(varchar(12), date_created, 110),'-','/') as [Date]
from address 
where date_last_modified BETWEEN DATEADD(Day,-1,GETDATE()) AND GETDATE()
order by id desc