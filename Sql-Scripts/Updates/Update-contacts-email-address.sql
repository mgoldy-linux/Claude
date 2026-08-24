--use P21Sand;
--use P21Play;
--use P21Dev3;
use P21;

select id, first_name,last_name,email_address
from dbo.contacts
where email_address like '%motion-ind%' and delete_flag = 'N'

update dbo.contacts
set email_address = REPLACE(email_address,'motion-ind','motion')
where email_address like '%motion-ind%'

select COUNT(*)[numOfemailadds]
from dbo.contacts
where email_address like '%motion-ind%' and delete_flag = 'N'

select id, first_name,last_name,email_address
from dbo.contacts
where email_address like '%motion.com' and delete_flag = 'N'

select id, first_name,last_name,email_address
from dbo.contacts
where id in (19385,29121,32801,9494,42646,42699,42656,31507,29136,31621)

select id, first_name,last_name,lower(email_address)[email_address]
from dbo.contacts
where id in (19385,29121,32801,9494,42646,42699,42656,31507,29136,31621)
