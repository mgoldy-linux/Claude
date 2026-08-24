select customer_name, delete_flag
from customer
where customer_id = 55118

select c.bill_to_contact_id,*
from address a
join customer c
on a.id = c.customer_id
where corp_address_id = 10806 and customer = 'Y' and c.delete_flag = 'N'
