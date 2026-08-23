use P21Sand;

select invoice_no,v.item_id,v.item_desc,ItemBrand,m.item_id,m.item_desc,m.class_id1,v.product_group_id,v.inv_mast_uid,m.default_sales_discount_group
from A_Invoice_Line_with_Hdr_Data_Olivia v
join inv_mast m
on v.inv_mast_uid = m.inv_mast_uid
where invoice_no = '113394'
--where ItemBrand is null and v.inv_mast_uid is not null and  m.default_sales_discount_group != 'D' -- v.product_group_id != 'OTHERCHG'

select il.inv_mast_uid
from invoice_line il
join inv_mast m
on il.inv_mast_uid = m.inv_mast_uid 
where il.invoice_no = '113394'

select class_id1,default_sales_discount_group, item_id
from inv_mast
where class_id1 is null  and default_sales_discount_group != 'D'
--where inv_mast_uid = 47138

update inv_mast
set class_id1 = 'LMS'
where inv_mast_uid = 47138

select distinct class_id1
from inv_mast
order by class_id1

select *
from inv_mast
where class_id1 = 'D50BS19H X 1 1/2      TTNCN'