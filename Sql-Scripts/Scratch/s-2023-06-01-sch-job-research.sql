select last_run_status, *
from scheduled_job
where description like '%510%'

select *
from p21_view_scheduled_job_notifications

select *
from p21_view_scheduled_job_history
where job_run_status = 'Failed'
order by date_created desc

select *
from inv_mast_assem_info