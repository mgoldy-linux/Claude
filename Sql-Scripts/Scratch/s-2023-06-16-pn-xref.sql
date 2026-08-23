Use P21Play;

Select  item_id, item_list_dtl.*
from dbo.item_list_dtl
join dbo.inv_mast 
on item_list_dtl.inv_mast_uid = inv_mast.inv_mast_uid
where item_list_hdr_uid = 3 and item_list_dtl.delete_flag = 'N' and 
order by date_created desc

select * 
from inv_xref
where customer_id = 53736