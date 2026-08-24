select item_id,upc_or_ean_id,item_desc,class_id1,class_id2,class_id3,class_id4,class_id5,inv_mast_uid,default_product_group
from inv_mast 
where item_id like '%RM' and default_product_group != 'B4'

select item_id,upc_or_ean_id,item_desc,class_id1,class_id2,class_id3,class_id4,class_id5,inv_mast_uid,default_product_group
from inv_mast 
where default_product_group like 'K1%'

select *
from inv_loc 
where product_group_id like 'K1%'

select item_id,upc_or_ean_id,item_desc,class_id1,class_id2,class_id3,class_id4,class_id5
from inv_mast 
where upc_or_ean_id like '400%'

select *
from address
where name like '%relia%'

select *
from inv_mast
where item_id like '%RM'

select *
from address
where name like '%Five%'

select item_id,upc_or_ean_id,item_desc,class_id1,class_id2,class_id3,class_id4,class_id5,inv_mast_uid,default_product_group
from inv_mast 
where item_id = 'SER21031RM'


select *
from inventory_supplier
where inv_mast_uid = 21476

select *
from supplier
where supplier_id = 16013