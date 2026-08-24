-- Quick check to see what emails sent
select recipients,reply_to,subject,send_request_date,sent_date,sent_status,copy_recipients,body,body_format,blind_copy_recipients
from msdb.dbo.sysmail_mailitems
--where sent_date >= DATEADD(day,datediff(day,0,Getdate())-2,0) --and recipients = 'lschneider@gmi3.com'
where sent_date between '2023-10-13 15:00:00' and '2023-10-14 00:00:00'
--where year(sent_date) = year(getdate()) and month(sent_date) = month(getdate()) and  day(sent_date) = day(getdate())-- and subject like '%Order%'--and copy_recipients like 'james%'--and blind_copy_recipients = 'mgoldyn@ptintl.com'
order by sent_date desc

select  job_config, start_date,*
from scheduled_job
where start_date  between '2020-10-12 15:00:00' and '2020-10-12 16:30:00' and created_by = 'PTIDOM\mgoldyn'

select *
from email_log
where transaction_number = 1135937

select transaction_number[Quote Number],subject,email_to,email_body,sender_name
from email_log
where email_to like '%Nobis%' and transaction_type = 'Quotation' and date_created > '2022-09-08'
order by date_created desc

select *
from email_log
where  date_created between '2023-05-31' and  '2023-06-02' and transaction_type = 'QUOTATION' -- 'ORDER ACKNOWLEDGEMENT' and
order by date_created desc

select *
from email_log
where  subject like '%Quote# 1599819%'
order by date_created desc

select *
from email_log
where  date_created between '2023-11-30' and  '2024-01-11' and transaction_type = 'QUOTATION' and created_by = 'FCAMMARATA'  -- 'ORDER ACKNOWLEDGEMENT' and
order by date_created desc