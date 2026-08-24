select item_id,item_desc,m.class_id1,u.legacy_item_id,u.legacy_item_description
from inv_mast m
join inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid
where default_sales_discount_group = 'Tritan'