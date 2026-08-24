select *
from import_suspense_hdr
where master_file_name like 'SOH00000357%'
--where master_file_name = 'SOH00000357_reimport081822092542.txt'

select *
from import_suspense_line
where import_suspense_hdr_uid = 8256

select cancel_flag, *
from oe_hdr 

where order_no = 1302719

select *
from oe_line 
where order_no = 1302719