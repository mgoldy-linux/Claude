select *
from scheduled_import_master
where active = 'Y'

select *
from company
where company_id = 1

select *
from system_setting
where system_setting_uid in (111,138,166,1064,1076) 

select *
from dbo.scheduled_job
where active_flag = 'Y'