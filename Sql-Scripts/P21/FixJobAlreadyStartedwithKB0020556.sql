use P21;
--use P21Play;

select *
from system_setting
where name = 'bypass_job_start_errors_flag'

exec p21_update_system_setting  'bypass_job_start_errors_flag', 'Y'

select *
from system_setting
where name = 'bypass_job_start_errors_flag'