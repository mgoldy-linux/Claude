--use P21Sand;
--use P21Play;
--use P21Dev3;
use P21;

select id, name,email_address
from dbo.address
where email_address like '%motion-ind%' and delete_flag = 'N'

update dbo.address
set email_address = REPLACE(email_address,'motion-ind','motion')
where email_address like '%motion-ind%'

select COUNT(*)[numOfemailadds]
from dbo.address
where email_address like '%motion-ind%' and delete_flag = 'N'

select id, name,email_address
from dbo.address
where email_address like '%motion.com' and delete_flag = 'N'

select id, name,email_address
from dbo.address
where id in (105069,88736,88737,92436,92437,104455,104457,89648,93348,105650)

select id, name,lower(email_address)[email_address]
from dbo.address
where id in (105069,88736,88737,92436,92437,104455,104457,89648,93348,105650)
