use P21Sand

select edi_export_path
from company
where company_id = 1

select *
from system_setting
where system_setting_uid in (1064,1076)

select *
from scheduled_import_master
where polling_path like '%\TPCX\%'

select name, description,start_date,scheduled_job_uid
from scheduled_job
where active_flag = 'Y'
order by date_created