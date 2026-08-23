select override_where, override_order_by,*
from p21_view_popup_statement 
where popup_detail_uid in (177,4857)

update popup_statement
set order_by = ''
where popup_detail_uid = 4857

update popup_statement
set order_by = 'inv_mast.item_desc,inv_mast.class_id1,inv_mast.class_id5'
where popup_detail_uid = 177

Select override_order_by, override_where, order_by,popup_statement_uid_parent,*
from popup_statement
where popup_detail_uid in (177,4857)


