--DS d_ds_custom_objects
SELECT custom_objects.custom_objects_uid ,custom_objects.configuration_id , COALESCE ( base_class.base_object, custom_objects.object) object ,             custom_objects.mod_string ,             custom_objects.date_last_modified ,             custom_objects.last_maintained_by ,             custom_objects.users_id ,             custom_objects.date_created ,             custom_objects.version_id ,             custom_objects.version_desc ,             custom_objects.role_id ,             custom_objects.type,       custom_objects.object_type,       custom_objects.default_values,       custom_objects.apply_to_all,       custom_objects.row_status_flag,       custom_objects.design_uid,       custom_objects.migrated_to_web 
FROM custom_objects   
INNER JOIN p21_view_custom_objects_base_class base_class
on (base_class.custom_objects_uid = custom_objects.custom_objects_uid)
WHERE (custom_objects.version_id = 'bl inside sales_bl inside sales') 