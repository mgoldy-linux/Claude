select * 
from import_suspense_hdr
where impexp_source_id = 'USERIMPORT'

select key_value[order_no],error_data,import_file_name,display_name,suspense_data,customer_id,location_id
from import_suspense_line
where import_file_path like '%CXM%'

-- find records in supend file
select *
from import_suspense_line
where error_data like '%Invalid%'

select carrier_id,*
from oe_hdr
--where order_no = 1092821
order by order_no desc