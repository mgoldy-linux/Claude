select  *
from scheduled_job_history
order by job_run_at_date desc

select top 10 *
from inv_mast
where class_id1 = 'Tritan' and class_id2 = 'EPL' and delete_flag = 'N'