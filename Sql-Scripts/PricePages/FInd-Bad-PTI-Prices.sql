-- 08/22/222 for MM PTI - fix NOT EPL Prices & assy prices

select item_id, item_desc,extended_desc, default_product_group, price1[price1 eff 07/01/22], price7[price7 10/25/21-06/30/22], price8[price8 4/19/21-10/24/22]
from inv_mast  
where class_id1 = 'PTI' and class_id2 = 'NOTEPL'  and delete_flag = 'N' and default_product_group != 'D1'

select item_id, item_desc,extended_desc, default_product_group, price1[price1 eff 07/01/22], price7[price7 10/25/21-06/30/22], price8[price8 4/19/21-10/24/22], class_id2
from inv_mast  
where class_id1 = 'PTI'  and delete_flag = 'N' and default_product_group != 'D1' and item_desc like '%assy'