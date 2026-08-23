--use P21Sand;
--use P21Play;
--use P21Dev3;
use P21;

select id, name,email_address
from dbo.address
where cast(email_address as varbinary(120)) !=  cast(lower(email_address) as varbinary(120)) and email_address like '%motion.com'

update dbo.address
set email_address = lower(email_address)
where cast(email_address as varbinary(120)) !=  cast(lower(email_address) as varbinary(120)) and email_address like '%motion.com'

select id, name,email_address
from dbo.address
where cast(email_address as varbinary(120)) !=  cast(lower(email_address) as varbinary(120)) and email_address like '%motion.com' and delete_flag = 'N'

select id, name,email_address
from dbo.address
where id in (59619,59893,115562,107858)