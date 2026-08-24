-- inside sales
select version_id,version_desc,role_id,sequence_no,object_name,attribute_name,attribute_value,cod.row_status_flag
from custom_objects co
join custom_objects_detail cod
on co.custom_objects_uid = cod.custom_objects_uid and attribute_name = 'enabled' and attribute_value = 'Y'
where role_id = 10
order by sequence_no

-- warehouse manager
select version_id,version_desc,role_id,sequence_no,object_name,attribute_name,attribute_value,cod.row_status_flag
from custom_objects co
join custom_objects_detail cod
on co.custom_objects_uid = cod.custom_objects_uid and attribute_name = 'enabled'
where role_id = 24
order by sequence_no

select *
from p21_view_dynachange_menu