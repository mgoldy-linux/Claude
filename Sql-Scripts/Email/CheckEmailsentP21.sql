-- Today
select importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients
from msdb.dbo.sysmail_mailitems
where year(sent_date) = year(getdate()) and month(sent_date) = month(getdate()) and  day(sent_date) = day(getdate()) --and subject like '%Order%'--and blind_copy_recipients = 'mgoldyn@ptintl.com'
order by sent_date desc

-- yesterday
select importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients,body_format
from msdb.dbo.sysmail_mailitems
where year(sent_date) = year(getdate()) and month(sent_date) = month(getdate()) and  day(sent_date) = day(dateadd(day,datediff(day,1,GETDATE()),0))
and copy_recipients like '%roy%'

-- 2 days ago
select recipients,subject,copy_recipients
from msdb.dbo.sysmail_mailitems
where year(sent_date) = year(getdate()) and month(sent_date) = month(getdate()) and  day(sent_date) = day(dateadd(day,datediff(day,2,GETDATE()),0))
and recipients != 'mgoldyn@solveindustrial.com'

-- looking for failed jobs
select * --importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients,send_request_date,mes
from msdb.dbo.sysmail_mailitems
where subject like '% job failed%'
order by sent_date desc

select importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients
from msdb.dbo.sysmail_mailitems
where subject like '%job fail%'
order by sent_date desc

select *
from msdb.dbo.sysmail_mailitems
where /*Copy_recipients like '%tgb%' --and */subject like '%1133100%'
order by sent_date desc

select * 
from msdb.dbo.sysmail_mailitems
where year(sent_date) = year(getdate()) and month(sent_date) = month(getdate()) and  day(sent_date) = day(dateadd(day,datediff(day,9,GETDATE()),0))
--where blind_copy_recipients = 'mgoldyn@ptintl.com'
order by sent_date -- desc

select * 
from msdb.dbo.sysmail_mailitems
where subject like '%1099168%'

-- last x days
select importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients,body_format
from msdb.dbo.sysmail_mailitems
where sent_date between DATEADD(day, -7, GETDATE()) and DATEADD(day, 1, GETDATE()) and recipients like 'Bick%'

select importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients,body_format
from msdb.dbo.sysmail_mailitems
where copy_recipients = 'shutch@solveindustrial.com'

select *
from msdb.dbo.sysmail_allitems
where copy_recipients = 'shutch@solveindustrial.com'

select *
from msdb.dbo.sysmail_event_log
order by log_date desc

select *
from msdb.dbo.sysmail_faileditems
order by sent_date desc

--- search for group or contact
select importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients,body_format
from msdb.dbo.sysmail_mailitems
where recipients like '%@nobisindustrial.com' --'%C-pts%'-- and sent_date > '2023-12-13'
order by sent_date desc


select importance,recipients,subject,sent_date,sent_status,copy_recipients,blind_copy_recipients,body_format
from msdb.dbo.sysmail_mailitems
where subject like '%southwest%' and sent_date > '2023-12-09'
order by sent_date desc