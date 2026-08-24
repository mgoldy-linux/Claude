select price1, price3
from inv_mast
where item_id = '2101059660'


select item_id, item_desc, price1,price3,price5,price10,class_id1, class_id2,default_product_group--,pl.price_library_id,pl.description,default_purchase_disc_group,multiplier
from inv_mast m
join price_library pl
on m.default_price_family_uid = pl.price_library_uid
where price3 > 0 and delete_flag = 'N'

select item_id, item_desc, price1,price3,price6,price10,class_id1, class_id2,default_product_group--,pl.price_library_id,pl.description,default_purchase_disc_group,multiplier
from inv_mast m
join price_library pl
on m.default_price_family_uid = pl.price_library_uid
where price1 = price6 and delete_flag = 'N' and price1 != 0


select item_desc, si.supplier_sort_code,cost
from inv_mast m
join inventory_supplier si
on m.inv_mast_uid = si.inv_mast_uid
--where item_id = '2101018164'
where cost = 3.15 and supplier_id = 16013


select *
from inv_mast
where extended_desc = 'HC207-21'