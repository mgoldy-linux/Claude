select name[Kaman_Branch_Name],c.customer_id,x.their_item_id,x.inv_mast_uid,item_id,item_desc,upc_or_ean_id
	from customer c	
	join address a
	on c.customer_id = a.id
	join inv_xref x
	on c.customer_id = x.customer_id
	join inv_mast im
	on im.inv_mast_uid = x.inv_mast_uid
	where c.class_2id = 'kaman' and c.delete_flag = 'N' 