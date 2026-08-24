--use P21Sand;
--use P21Play;
--use P21Dev3;
use P21;

select id, first_name,last_name,email_address
from dbo.contacts
where email_address like '%motion.com' and delete_flag = 'N'

update dbo.contacts
set email_address = lower(email_address)
where email_address like '%motion.com'

select id, first_name,last_name,email_address
from dbo.contacts
where email_address like '%motion.com' and delete_flag = 'N'