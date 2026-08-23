select ins.upc_code [UPC Number],item_id[Item Number],legacy_item_id,m.price1[Published List Price],m.price7[Before070122],m.price8[Before102521],p.product_group_desc[Description2 (Product Line)],m.class_id2
from inv_mast m
join inv_loc il
on m.inv_mast_uid = il.inv_mast_uid
join product_group p
on m.default_product_group = p.product_group_id
join item_uom u
on u.inv_mast_uid = m.inv_mast_uid
join inv_mast_ud n
on m.inv_mast_uid = n.inv_mast_uid
join inventory_supplier ins
on ins.inv_mast_uid = m.inv_mast_uid
where m.class_id1 = 'IPTCI' and m.delete_flag = 'N' /*and location_id = 300*/ and m.price1 != 0
order by [Description2 (Product Line)]