select default_product_group, item_id, item_desc
from inv_mast 
where inv_mast_uid = 132841

update dbo.inv_mast
set default_product_group = 'D1'
where inv_mast_uid = 132841

select default_product_group, item_id, item_desc
from inv_mast 
where inv_mast_uid = 132841