select item_desc, upc_or_ean_id, si.upc_code,class_id1,item_id,default_product_group
from inv_mast m
join inventory_supplier si
on m.inv_mast_uid = si.inv_mast_uid
where class_id2 = 'EPL' and class_id1 is not null and ( upc_or_ean_id is not null and si.upc_code is not null)

