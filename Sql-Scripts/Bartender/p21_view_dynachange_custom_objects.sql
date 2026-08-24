SELECT co.version_id,co.version_desc,co.role_id,co.type,co.object_type,co.apply_to_all,migrated_to_web
	,cod.custom_objects_detail_uid
	,cod.custom_objects_uid detail_custom_objects_uid
	,cod.sequence_no
	,cod.object_name
	,cod.attribute_name
	,cod.attribute_value
	,cod.row_status_flag detail_row_status_flag
	,cod.date_created detail_date_created
	,cod.created_by detail_created_by
	,cod.date_last_modified detail_date_last_modified
	,cod.last_maintained_by detail_last_maintained_by
FROM custom_objects co
LEFT JOIN custom_objects_detail cod
ON co.custom_objects_uid = cod.custom_objects_uid 
where role_id = 1 and version_id = 'Branch_and_source_124'