	select m.item_id[SIMG#],item_desc[Part#],mu.legacy_item_description[Item Description],m.short_code[Legacy Part#],default_price_family_uid
	from inv_mast m
	join inv_mast_ud mu
	on m.inv_mast_uid = mu.inv_mast_uid
	where m.item_desc like 'M-%' and (default_price_family_uid not in (5,34,38) or default_price_family_uid is null)
	order by Part# 