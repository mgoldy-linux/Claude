select version_id,version_desc,role_id,sequence_no,object_name,attribute_name,attribute_value,cod.row_status_flag
from custom_objects co
join custom_objects_detail cod
on co.custom_objects_uid = cod.custom_objects_uid
where version_id = 'role_inside sales manager' and attribute_name = 'enabled'-- and object_name not like '%_r' 
order by sequence_no

select version_id,version_desc,role_id,sequence_no,object_name,attribute_name,attribute_value,cod.row_status_flag
from custom_objects co
join custom_objects_detail cod
on co.custom_objects_uid = cod.custom_objects_uid
where version_id = 'Warehouse_Manager_warehouse manager' and attribute_name = 'enabled' -- and object_name not like '%_r'
order by sequence_no

select version_id,version_desc,role_id,sequence_no,object_name,attribute_name,attribute_value,cod.row_status_flag
from custom_objects co
join custom_objects_detail cod
on co.custom_objects_uid = cod.custom_objects_uid
where version_id = 'role_management / accounting' and attribute_name = 'enabled' -- and object_name not like '%_r'
order by sequence_no


select *
from custom_objects 
where role_id = 16

select role_uid, role
from roles

select *
from roles
where role_uid = 3