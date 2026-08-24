use P21Dev3;

select custom_objects_uid,users_id, object,configuration_id,version_id,version_desc,type,cuo.row_status_flag, code_description
from dbo.custom_objects cuo
join code_p21 c21
on cuo.row_status_flag = c21.code_no
where version_id = 'Assembly_Maintenance_General (11.29.2022-RS)'

select *
from dbo.custom_objects
where custom_objects_uid = 865

select *
from dbo.custom_objects_detail
where custom_objects_uid = 865

delete
from dbo.custom_objects_detail
where custom_objects_uid = 865

delete
from dbo.custom_objects
where custom_objects_uid = 865

select *
from dbo.custom_objects
where custom_objects_uid = 865

select *
from dbo.custom_objects_detail
where custom_objects_uid = 865