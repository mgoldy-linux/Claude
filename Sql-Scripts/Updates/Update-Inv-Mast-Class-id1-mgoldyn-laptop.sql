use P21Sand;

select invoice_no,v.item_id,v.item_desc,ItemBrand,m.item_id,m.item_desc,m.class_id1,v.product_group_id,v.inv_mast_uid,m.default_sales_discount_group
from A_Invoice_Line_with_Hdr_Data_Olivia v
join inv_mast m
on v.inv_mast_uid = m.inv_mast_uid
where ItemBrand is null and v.inv_mast_uid is not null and  m.default_sales_discount_group != 'D'

update dbo.inv_mast
set class_id1 = default_sales_discount_group
where class_id1 is null and default_sales_discount_group != 'D'

select invoice_no,v.item_id,v.item_desc,ItemBrand,m.item_id,m.item_desc,m.class_id1,v.product_group_id,v.inv_mast_uid,m.default_sales_discount_group
from A_Invoice_Line_with_Hdr_Data_Olivia v
join inv_mast m
on v.inv_mast_uid = m.inv_mast_uid
where ItemBrand is null --and v.inv_mast_uid is not null and  m.default_sales_discount_group != 'D'