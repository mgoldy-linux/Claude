select *
from alert_recipient
where alert_email_address  = 'mgoldyn@ptintl.com'

update alert_recipient
set alert_email_address = 'mgoldyn@solveindustrial.com',alert_email_name = 'MG'
where alert_email_address  = 'mgoldyn@ptintl.com'

select *
from alert_recipient
where alert_email_address  = 'mgoldyn@ptintl.com'

select *
from alert_recipient
where alert_email_address  = 'mgoldyn@solveindustrial.com'