Use Play2;

Select popup_detail_uid,override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 4885


Use P21;

Select popup_detail_uid,override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 4885

update dbo.popup_statement
set override_order_by = 'A', order_by = 'inv_mast.item_desc,inv_mast.class_id1,inv_mast.class_id5'
where popup_detail_uid = 4885

Select popup_detail_uid,override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 4885
