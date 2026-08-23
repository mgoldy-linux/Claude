--DS d_ds_class
SELECT class.class_type,     class.class_number,     class.class_id,     class.class_description,     class.delete_flag,     class.date_created,     class.date_last_modified,     class.last_maintained_by,     class.logo_path_filename,     class.export_class_flag,     class.class_uid     ,class.avail_for_cycle_count_flag 
FROM class WHERE (class_type = 'IV') AND (class_number = 1) AND (class_id = 'PTI') AND ( (class.delete_flag <> 'Y' ) ) 

SELECT   code_p21.code_description ,                code_p21.code_no     ,     code_p21.code_sub_description  FROM   code_p21     INNER JOIN code_x_code_group_p21 ON code_x_code_group_p21.code_no = code_p21.code_no     WHERE ( code_x_code_group_p21.code_group_no = 1181 )    

select *
from class
where class_description like 'PTI%'