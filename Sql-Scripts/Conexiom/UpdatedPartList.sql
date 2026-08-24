Select ivs.upc_code,
	case
		when im.short_code is null then im.item_id
		else im.short_code End[short_code],
		im.item_id,im.item_id,im.upc_or_ean_id,im.last_maintained_by
from inventory_supplier ivs
join inv_mast im
on ivs.inv_mast_uid = im.inv_mast_uid
where im.class_id2 = 'EPL' and im.date_created > '2020-09-10'
order by im.item_id 