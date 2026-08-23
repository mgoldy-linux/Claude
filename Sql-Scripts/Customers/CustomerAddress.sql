use p21;

select customer_id, customer_name, a.mail_address1,a.mail_address2,a.mail_address3
from customer c
join address a
on c.customer_id = a.id
where a.corp_address_id = 10806 and c.delete_flag = 'N' --and mail_address3 is Not null