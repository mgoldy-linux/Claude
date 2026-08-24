Use P21;
--Use Play2;

/*
-- two different popups - one for header & one for the line
parent = 1566 child = 4871
parent = 3903 child = 4865
Select override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 4865

update popup_statement
set override_order_by = 'A'
where popup_detail_uid = 4865
*/
Select override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid in (177,3913)

update popup_statement
--set order_by = ''
set order_by = 'inv_mast.item_desc,inv_mast.class_id1,inv_mast.class_id5'
where popup_detail_uid in (177,3913)

Select override_order_by, override_where, order_by,popup_statement_uid_parent,*
from popup_statement
where popup_detail_uid in (177,3913)

select override_where, override_order_by,*
from p21_view_popup_statement 
where popup_detail_uid in (4857,4885)


