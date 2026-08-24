


select id,first_name,last_name,email_address
from dbo.contacts
where email_address = 'bwolf@ptintl.com'

select id
from dbo.users
where email_address = 'bwolf@ptintl.com'

select alert_recipient_uid
from dbo.alert_recipient 
where alert_email_address = 'gdib@ptintl.com'

select *
from dbo.alert_recipient 
where alert_recipient_uid in (18, 85)