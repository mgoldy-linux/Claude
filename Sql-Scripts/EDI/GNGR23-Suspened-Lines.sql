select key_value[order_no],error_data,suspense_data,format(order_date,'yyyy-MM-dd')[order_date],po_no,v.location_id,import_suspense_line_uid,import_suspense_hdr_uid,
import_set_no,(import_file_path + import_file_name)[import_file]
from dbo.p21_view_import_suspense_line v
left join dbo.oe_hdr h
on v.key_value = h.order_no 
where v.customer_id = 54210 -- and (error_data like '%This item ID is not valid.%' or error_data like '%Pricing Unit%' or error_data like '%Multiple contracts%' )
order by import_set_no