Use P21;
--Use Play2;

select c.customer_id,customer_name,corp_address_id,mail_address1,mail_address2,mail_address3,mail_city,mail_state,mail_postal_code,central_phone_number,s.ship_to_id
from customer c
join address a
on c.customer_id = a.id
join ship_to s
on c.customer_id = s.customer_id
where c.delete_flag = 'N' and a.delete_flag = 'N' and customer_name like '%Grainger%' 
--order by c.date_last_modified desc