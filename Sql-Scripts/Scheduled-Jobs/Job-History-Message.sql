select top 9 *
from dbo.scheduled_job_history
--where message like '%420%' and job_run_status = 'Canceled'
order by job_run_at_date desc

select top 9 *
from dbo.scheduled_job_history
where message like '%430%' and job_run_status = 'Failed'
order by job_run_at_date desc

select top 9 *
from dbo.scheduled_job_history
where message like '%EDI%' and job_run_status = 'Failed'
order by job_run_at_date desc

select top 100 *
from dbo.scheduled_job_history
where message like '%Daily-420%' and job_run_status != 'Started'
order by job_run_at_date desc

select top 1000 *
from dbo.scheduled_job_history
where message like '%Daily-470%' and job_run_status != 'Started'
order by job_run_at_date desc

select top 16 *
from oe_hdr
order by date_created desc

select *
from company