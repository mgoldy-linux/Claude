SELECT system_setting.system_setting_uid, system_setting.configuration_id, system_setting.module_cd, system_setting.name, system_setting.value, system_setting.data_type_cd, system_setting.data_type_length, system_setting.data_type_scale, system_setting.date_created, system_setting.date_last_modified, system_setting.last_maintained_by 
FROM system_setting 
WHERE system_setting.configuration_id in (0, 4585)
order by date_last_modified desc

