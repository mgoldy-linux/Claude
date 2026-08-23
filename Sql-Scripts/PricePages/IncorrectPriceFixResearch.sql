select item_id, price1, price8, price9, inv_mast_uid, default_product_group
from inv_mast
where price1 = price8 and class_id2 = 'NOTEPL' and class_id1 = 'PTI' and default_product_group not in ('GS','D1') and delete_flag = 'N' and price1 != 0

select item_id, item_desc, price1, price8, price9, class_id1, class_id2, inv_mast_uid, default_product_group
from inv_mast
where item_desc like 'SRE-PB2%'

--S1 product group 
select item_id, item_desc,price1, price8, price9, inv_mast_uid, default_product_group,class_id2
from inv_mast
where price1 = price8 /*and class_id2 = 'NOTEPL'*/ and class_id1 = 'PTI' and default_product_group = 'S1' and delete_flag = 'N' and price1 != 0