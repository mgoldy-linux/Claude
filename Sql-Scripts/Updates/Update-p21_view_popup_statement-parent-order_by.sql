--Use P21;
--Use Play2;
use P21Play;

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
/*
Select override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid in (1566,3903,177,3882,3912)

update popup_statement
--set order_by = ''
set order_by = 'inv_mast.item_desc,inv_mast.class_id1,inv_mast.class_id5'
where popup_detail_uid in (1566,3903,177,3882,3912)

Select override_order_by, override_where, order_by,popup_statement_uid_parent,*
from popup_statement
where popup_detail_uid in (1566,3903,177,3882,3912)

select override_where, override_order_by,*
from p21_view_popup_statement 
where popup_detail_uid in (4871,4865,4860,4857,4885)
*/
/* colums info
 INV_MAST.SHORT_CODE short_code, INV_MAST.ITEM_ID,               INV_MAST.ITEM_DESC ,              'Y' protect,              inv_mast.product_type,  CASE inv_mast.product_type  WHEN 'L' THEN 'Lot Group'  WHEN 'C' THEN 'Mercury Captive'  WHEN 'G' THEN 'Mercury Target'  WHEN 'M' THEN 'Mueller'  WHEN 'N' THEN 'Non-Mercury'  WHEN 'R' THEN 'Regular'  WHEN 'E' THEN 'Service Contract'  WHEN 'B' THEN 'Subtotal'  WHEN 'T' THEN 'Temporary'  ELSE inv_mast.product_type END as product_type_description,              inv_mast.price1,              inv_mast.inv_mast_uid
*/

-- item inquiry
Select override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid = 177

update dbo.popup_statement
set order_by = 'inv_mast.item_id'
where popup_detail_uid = 177

Select popup_statement_uid_parent,override_order_by, override_where, order_by,*
from popup_statement
where popup_detail_uid in (177,4857)

select *
from popup_statement
where order_by = ',inv_mast.item_desc'


Select override_order_by, override_where, order_by,popup_statement_uid_parent,*
from popup_statement
where popup_detail_uid = 4857


update popup_statement
set order_by = 'inv_mast.item_desc,inv_mast.class_id1,inv_mast.class_id5'
where popup_detail_uid in (177,4857)


select override_where, override_order_by,*
from p21_view_popup_statement 
where popup_detail_uid in (177,4857)

Select override_order_by, override_where, order_by,popup_statement_uid_parent,*
from popup_statement
where popup_detail_uid in (1566,3903,3882,3912)


Select override_order_by, override_where, order_by,popup_statement_uid_parent,*
from popup_statement
where popup_statement_uid_parent in (1566,3903,3882,3912)