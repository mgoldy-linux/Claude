use p21;

--DS d_dw_scheduled_task_edit
SELECT DISTINCT scheduled_job.scheduled_job_uid, scheduled_job.company_id, scheduled_job.name,scheduled_job.description,scheduled_job.job_config, scheduled_job.active_flag,scheduled_job.created_by 
FROM scheduled_job   
LEFT JOIN scheduled_job_x_users 
ON scheduled_job.scheduled_job_uid = scheduled_job_x_users.scheduled_job_uid   
LEFT JOIN scheduled_job_x_roles ON scheduled_job.scheduled_job_uid = scheduled_job_x_roles.scheduled_job_uid 
WHERE scheduled_job.delete_flag = 'N' AND name like '%Fast%' and ( scheduled_job.type NOT IN (SELECT code_p21.code_description              
FROM code_p21             
INNER JOIN code_x_code_group_p21 ON code_p21.code_no = code_x_code_group_p21.code_no              
WHERE code_x_code_group_p21.code_group_no = 2288 )) AND scheduled_job.recurrence_type <> 0

select job_config
from scheduled_job
where scheduled_job_uid = 635005