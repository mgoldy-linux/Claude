exec sp_who2

select *
from scheduled_job
WHERE scheduled_job_uid = 397834 

UPDATE "scheduled_job" SET "active_flag" = 'N' WHERE scheduled_job_uid = 397834 AND "active_flag" = 'N' AND "delete_flag" = 'N' AND "history_level" = 1360 AND "max_retry_attempts" IS NULL 

Update scheduled_job 
set running_flag = 'N'
WHERE scheduled_job_uid = 397834 