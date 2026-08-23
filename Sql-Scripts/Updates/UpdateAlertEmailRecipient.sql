/*
	11/25/2020 - update both rlinke@ptintl.com;gdib@ptintl.com and gdib@ptintl.com;rlinke@ptintl.com;
	12/08/2020 - tested on laptop verision - sat
*/

--use P21PlayLocal;
--use P21Local;
--use P21Play;
--use Play2;
use P21;

select subject, ar.alert_email_address,ar.alert_email_name
from alert_message ai
join alert_recipient ar
on ai.alert_message_uid = ar.alert_message_uid
where (alert_email_address = 'rlinke@ptintl.com;gdib@ptintl.com'  or alert_email_address = 'gdib@ptintl.com;rlinke@ptintl.com') and ar.row_status_flag = 704
order by alert_email_name

Update alert_recipient
set alert_email_address = 'gdib@solveindustrial.com;rlinke@solveindustrial.com',alert_email_name = 'GD&RL'
where alert_email_address = 'gdib@ptintl.com;rlinke@ptintl.com'

Update alert_recipient
set alert_email_address = 'gdib@solveindustrial.com;rlinke@solveindustrial.com',alert_email_name = 'GD&RL'
where alert_email_address = 'rlinke@ptintl.com;gdib@ptintl.com'

select subject, ar.alert_email_address,ar.alert_email_name
from alert_message ai
join alert_recipient ar
on ai.alert_message_uid = ar.alert_message_uid
where alert_email_address = 'gdib@ptintl.com;rlinke@ptintl.com' and ar.row_status_flag = 704
order by alert_email_name

select ai.alert_message_uid,ai.subject, ar.alert_email_address,ar.alert_email_name
from alert_message ai
join alert_recipient ar
on ai.alert_message_uid = ar.alert_message_uid
where alert_email_address = 'gdib@solveindustrial.com;rlinke@solveindustrial.com' and ar.row_status_flag = 704
order by alert_message_uid