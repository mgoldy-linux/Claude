--- need to use replace? or powershell

select id, name, email_address
from users
where delete_flag = 'N' and email_address is not null and email_address like '%@ptintl.com'

