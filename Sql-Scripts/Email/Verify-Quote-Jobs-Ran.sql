/*
	02/03/2020 created as a way to tell me that jobs emails ran correctly
	03/01/2024 - alpha count
*/

Declare @jname as varchar(50),
		@jlrundate varchar(10),
		@jlruntime varchar(10),
		@jMessage varchar(250),
		@numAlpha varchar(2),
		@ebody varchar(320);
Use P21;

select @numAlpha = count(*)
from dbo.oe_hdr
where order_no not like '%[^A-Za-z]%'

USE [msdb]
		
select @jname = name from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Quotes Reports'		
	
select @jlrundate = sj.last_run_date
from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Quotes Reports'
	
select @jlruntime = SJ.last_run_time
from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Quotes Reports'
		
select @jMessage = last_outcome_message
from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Quotes Reports'
        
set @ebody = @jname + ' last ran on '  + @jlrundate + ':' + @jlruntime + ' and the ' + @jMessage + ' and number of ALPHA orders: ' + @numAlpha

EXEC sp_send_dbmail
@profile_name = 'P21Alerts',
@recipients = 'repairgroup.gmi@gmail.com',
@reply_to = 'reports@solveindustrial.com',
@subject = 'Quotes Jobs Results Email',
@body = @ebody;