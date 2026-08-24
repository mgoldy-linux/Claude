select key_value[order_no],error_data,suspense_data,format(order_date,'yyyy-MM-dd')[order_date],po_no,v.location_id,import_suspense_line_uid,import_suspense_hdr_uid,
import_set_no,(import_file_path + import_file_name)[import_file]
from dbo.p21_view_import_suspense_line v
left join dbo.oe_hdr h
on v.key_value = h.order_no 
where v.customer_id = 49889 and (error_data like '%This item ID is not valid.%' or error_data like '%Pricing Unit%' or error_data like '%Multiple contracts%' )
order by import_set_no

/*
select *
from import_suspense_hdr
where master_file_name = 'SOH00000348_reimport092222144409.txt'

select *
from p21_view_import_suspense_hdr


select customer_part_number,line_no,*
from oe_line
where order_no = 1302452 and customer_part_number = '35397850'

select *
from p21_view_import_suspense_line
where import_suspense_line_uid = 30011
*/