/*
	02/03/2020 created as a way to tell me that sales' jobs emails ran correctly 03/07/24 - add alpha

*/


	
Declare @jname as varchar(50),
		@jlrundate varchar(10),
		@jlruntime varchar(10),
		@jMessage varchar(250),
		@numAlpha int,
		@ebody varchar(320);

Use P21;

select @numAlpha = count(*)
from dbo.oe_hdr
where order_no not like '%[^A-Za-z]%'

USE [msdb]

select @jname = name 
from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Sales Reports'		

select @jlrundate = sj.last_run_date
from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Sales Reports'
	
select @jlruntime = SJ.last_run_time
from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Sales Reports'
		
select @jMessage = last_outcome_message
from sysjobs s
join sysjobservers sj
on s.job_id = sj.job_id
where name = '_mg_Email Daily Sales Reports'

set @ebody = @jname + ' last ran on '  + @jlrundate + ':' + @jlruntime + ' and the ' + @jMessage + ' and number of ALPHA orders: ' + @numAlpha

EXEC sp_send_dbmail
@profile_name = 'P21Alerts',
@recipients = 'repairgroup.gmi@gmail.com',
@reply_to = 'reports@solveindustrial.com',
@subject = 'Sales Jobs Results Email',
@body = @ebody;
