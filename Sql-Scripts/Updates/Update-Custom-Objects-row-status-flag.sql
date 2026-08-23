--use P21Dev3;
use Play2;

select custom_objects_uid,users_id, object,configuration_id,version_id,version_desc,type,cuo.row_status_flag, code_description
from dbo.custom_objects cuo
join code_p21 c21
on cuo.row_status_flag = c21.code_no
where version_id = 'Assembly_Maintenance_General (11.29.2022-RS)'


-- 705 = inactive
update dbo.custom_objects
set row_status_flag = '705'
where custom_objects_uid = 865

select custom_objects_uid,users_id, object,configuration_id,version_id,version_desc,type,cuo.row_status_flag, code_description
from dbo.custom_objects cuo
join code_p21 c21
on cuo.row_status_flag = c21.code_no
where version_id = 'Assembly_Maintenance_General (11.29.2022-RS)'

--update detail
SELECT  *
FROM  dbo.custom_objects_detail
where custom_objects_uid = 865

update dbo.custom_objects_detail
set row_status_flag = 705
where custom_objects_uid = 865

SELECT  *
FROM  dbo.custom_objects_detail
where custom_objects_uid = 865
