--Scheduled Task History Tab on Scheduled Task Manager: API orders
SELECT
   top 1000 scheduled_job_history.scheduled_job_history_uid,
   scheduled_job_history.scheduled_job_uid,
   scheduled_job_history.job_run_at_date,
   scheduled_job_history.job_run_status,
   scheduled_job_history.message,
   scheduled_job_history.created_by
FROM
   scheduled_job_history
ORDER BY
   job_run_at_date DESC