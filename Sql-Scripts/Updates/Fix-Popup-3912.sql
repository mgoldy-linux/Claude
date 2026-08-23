Use P21Play;

Select popup_detail_uid,override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 3912

Use P21;

Select popup_detail_uid,override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 3912

update popup_statement
--set order_by = ''
set order_by = 'inv_mast.item_id ASC'
where popup_detail_uid = 3912

Select popup_detail_uid,override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 3912