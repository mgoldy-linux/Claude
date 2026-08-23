select distinct m.item_id,m.item_desc,il.product_group_id,m.inv_mast_uid,
	case when product_group_id not like 'K%' then m.upc_or_ean_id
	else their_item_id
	end, m.extended_desc,m.class_id1,m.class_id5
	From inv_mast m
	join inv_loc il
	on m.inv_mast_uid = il.inv_mast_uid and m.delete_flag = 'N'
	left join inv_xref  x
	on m.inv_mast_uid = x.inv_mast_uid
	where item_desc not like 'D-%' and location_id = 100 and  qty_on_hand > 0
