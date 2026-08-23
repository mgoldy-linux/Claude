select completed,cancel_flag, delete_flag,*
from oe_hdr
where order_no = 1435029

select line_no,complete, cancel_flag, ol.delete_flag,item_id,M.inv_mast_uid,ol.*
from dbo.oe_line ol
join dbo.inv_mast m
on ol.inv_mast_uid = m.inv_mast_uid
where order_no = 1435029
order by ol.line_no

update dbo.oe_line
set delete_flag = 'Y'
where order_no = 1435029 and line_no = 6

select *
from invoice_hdr 
where order_no = '1435029'