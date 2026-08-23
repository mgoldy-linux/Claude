select top 7 created_by, message, job_run_at_date, scheduled_job_uid 
from scheduled_job_history
where job_run_status = 'Failed' 
order by job_run_at_date desc

select *
from scheduled_job_history
where message like '%zoro%'
order by job_run_at_date desc

select *
from scheduled_job
where description like '%zoro%'


select *
from dbo.scheduled_job_feature
--where scheduled_job_uid = 558969
order by date_last_modified desc