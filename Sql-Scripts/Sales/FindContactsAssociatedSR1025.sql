select c.customer_id,a.name,first_name,last_name,direct_phone,a.central_phone_number,co.email_address,a.email_address[alt_email],phys_address1,phys_address2,phys_city,phys_state,phys_postal_code 
from customer c
join address a
on c.customer_id = a.id
join contacts co
on c.customer_id = co.address_id
where salesrep_id = 1025 and c.credit_status != 'INACTIVE'


