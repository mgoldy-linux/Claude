use P21Sand;

select id,first_name,last_name,email_address
from contacts
where email_address like '%motion-ind%'

select id,first_name,last_name,email_address
from contacts
where email_address not like '%@%' and email_address != ' '
