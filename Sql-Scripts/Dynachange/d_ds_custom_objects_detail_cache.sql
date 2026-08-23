--DS d_ds_custom_objects_detail_cache
SELECT custom_objects_detail.custom_objects_detail_uid    , custom_objects_detail.custom_objects_uid    , custom_objects_detail.sequence_no    , custom_objects_detail.object_name    , custom_objects_detail.attribute_name    , custom_objects_detail.attribute_value    , custom_objects_detail.row_status_flag    , custom_objects_detail.date_created    , custom_objects_detail.created_by    , custom_objects_detail.date_last_modified    , custom_objects_detail.last_maintained_by    , 0 c_xposition    , 0 c_title     , COALESCE (autopop_info.auto_populate_flag , 'N') auto_populate_flag    , autopop_info.value_source_column     , autopop_info.value_source_table     , autopop_info.value_source_expression 
FROM custom_objects_detail   
LEFT OUTER JOIN p21_view_autopop_info autopop_info 
ON ( autopop_info.custom_objects_detail_uid = custom_objects_detail.custom_objects_detail_uid ) 
WHERE (autopop_info.area_configuration_id IS NULL OR autopop_info.area_configuration_id = 4585 )  AND (autopop_info.info_configuration_id IS NULL OR autopop_info.info_configuration_id = 4585 ) AND custom_objects_detail.custom_objects_uid  IN (824, 829, 801, 637, 639, 640, 641, 642, 645, 649, 651, 657, 660, 662, 663, 664, 665, 671, 673, 675, 676, 677, 678, 679, 704, 813, 815, 823, 824, 825, 827, 829) AND ( (custom_objects_detail.row_status_flag <> 700) )  
ORDER BY custom_objects_detail.custom_objects_detail_uid

