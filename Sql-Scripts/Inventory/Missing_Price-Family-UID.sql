--extract of SIMG#, Item ID, Product Group & Desc, Purchase Group ID, and Default Price Family for any currently active SKUs in live where Default Price Family is Null.



select item_id,item_desc,mu.legacy_item_id,default_product_group, default_purchase_disc_group
from inv_mast m
join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where default_price_family_uid is null and m.delete_flag = 'N'