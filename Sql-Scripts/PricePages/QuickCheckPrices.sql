select inv_mast_uid,item_id,item_desc,class_id1,class_id2,price1,price8,default_product_group
from inv_mast
where class_id1 = 'PTI'and class_id2 = 'EPL'

select inv_mast_uid,item_id,item_desc,class_id1,class_id2,price1,price8,default_product_group
from inv_mast
where class_id1 = 'IPTCI' and price1 > 0