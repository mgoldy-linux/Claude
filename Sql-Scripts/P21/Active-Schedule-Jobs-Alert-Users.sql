select *
from scheduled_job_user_notifications
where scheduled_job_uid = 443089

select name, description,repeat_days,last_run_status,consecutive_failure_counter,run_once,users,notification_uid
from dbo.scheduled_job sj
left join scheduled_job_user_notifications sjun
on sj.scheduled_job_uid = sjun.scheduled_job_uid
where active_flag = 'Y' --and name like '%Tran%'
order by name