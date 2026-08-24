select distinct sv.order_no,customer_part_number,sv.item_desc,sv.item_id,im.upc_or_ean_id,im.short_code,po_no,sv.source_code_no,sv.customer_name
from p21_sales_history_report_view sv
join inv_mast im
on sv.inv_mast_uid = im.inv_mast_uid
where order_date > '09/30/2019' and ship_loc_id = 100 and source_code_no = 706 --and customer_name like '%BDI%'
order by customer_name