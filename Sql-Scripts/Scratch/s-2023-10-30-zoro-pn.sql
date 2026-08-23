select their_item_id,m.inv_mast_uid,item_id, item_desc
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where customer_id = 55932 and their_item_id = 'G2082538'


select their_item_id,m.inv_mast_uid,item_id, item_desc
from item_list_dtl ild
join inv_mast m
on ild.inv_mast_uid = m.inv_mast_uid
join inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where item_list_hdr_uid = 1 and their_item_id = 'G208091098' and customer_id = 55932

select COUNT(*) [On846]
from item_list_dtl
where item_list_hdr_uid = 1 and delete_flag = 'N'

select COUNT(*) [OnXref]
from inv_xref x
where customer_id = 55932

select *
from item_list_dtl
where item_list_hdr_uid = 1 and inv_mast_uid = 82436

select their_item_id,m.inv_mast_uid,item_id, item_desc,item_list_dtl_uid
from item_list_dtl ild
join inv_mast m
on ild.inv_mast_uid = m.inv_mast_uid
join inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where item_list_hdr_uid = 1 and item_desc = 'GEZ 100ES' and customer_id = 55932

select territory_desc,*
from A_Invoice_line_with_hdr_data_Base
where customer_id = 10926
