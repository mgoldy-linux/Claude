--use P21Play;


select *
from cust_defaults_email_defaults

select *
from custom_objects
--where type = 'R' and role_id = 40
--where role_id= 10 
where date_created > '2021-10-26'
order by date_created desc

select *
from popup_detail

select *
from dbo.custom_objects cuo
join code_p21 c21
on cuo.row_status_flag = c21.code_no
where version_id = 'Assembly_Maintenance_General (11.29.2022-RS)'


select distinct row_status_flag
from dbo.custom_objects