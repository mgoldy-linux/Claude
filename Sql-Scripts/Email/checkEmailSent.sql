-- Quick check to see what emails sent
select recipients,reply_to,subject,send_request_date,sent_date,sent_status,copy_recipients,body,body_format,blind_copy_recipients
from msdb.dbo.sysmail_mailitems
--where sent_date >= DATEADD(day,datediff(day,0,Getdate())-2,0) --and recipients = 'lschneider@gmi3.com'
--where sent_date between '2020-09-21 15:00:00' and '2020-09-21 16:00:00'
where year(sent_date) = year(getdate()) and month(sent_date) = month(getdate()) and  day(sent_date) = day(getdate())-- and subject like '%Order%'--and copy_recipients like 'james%'--and blind_copy_recipients = 'mgoldyn@ptintl.com'
order by sent_date desc

select  job_config, start_date,*
from scheduled_job
where start_date  between '2020-10-12 15:00:00' and '2020-10-12 16:30:00' and created_by = 'PTIDOM\mgoldyn'

select *
from email_log
where transaction_number = 1135937

select transaction_number[Quote Number],subject,email_to,email_body,sender_name, date_created
from email_log
where email_to like '%Nobis%' and transaction_type = 'Quotation' and date_created > '2022-09-08'
order by date_created desc

select * --distinct sender_name
from email_log
where  date_created between '2024-03-13' and  '2024-03-18' and transaction_type = 'QUOTATION' and sender_name like '%Dan%'--and subject like '%1639948%'--and sender_name like 'Frank Cammarata'-- 'ORDER ACKNOWLEDGEMENT' and
order by date_created desc

select top 7*
from email_log
where  email_cc like '%@ProPowerReps.com%' or email_to like '%@ProPowerReps.com%' --and date_created < '2024-03-15'
order by date_created desc 

select *
from email_log
where  date_created between '2023-11-01' and  '2024-04-08' and email_to like '%Nobis%' -- and sender_name like 'Frank Cammarata' 
order by date_created desc

select *
from email_log
where  date_created between '2023-11-01' and '2024-01-19' and email_to like '%Nobis%'
order by date_created desc

select recipients,reply_to,subject,send_request_date,sent_date,sent_status,copy_recipients,body,body_format,blind_copy_recipients
from msdb.dbo.sysmail_mailitems
--where sent_date >= DATEADD(day,datediff(day,0,Getdate())-2,0) --and recipients = 'lschneider@gmi3.com'
--where sent_date between '2020-09-21 15:00:00' and '2020-09-21 16:00:00'
where year(sent_date) = year(getdate()) and month(sent_date) = month(getdate()) and  day(sent_date) = day(getdate()) and body like '%1639948%'
