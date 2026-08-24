select item_id,''[NewPrice1],default_product_group,legacy_item_id,legacy_item_description,Price1,price7,price8
from inv_mast m
join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where price1 = price7 and class_id1 = 'IPTCI' and class_id2 = 'NOTEPL' and delete_flag = 'N' and Price1 != 0
order by m.date_created desc
