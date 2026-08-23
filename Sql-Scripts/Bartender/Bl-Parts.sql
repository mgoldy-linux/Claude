select distinct item_desc[legacy_item_id],item_id,
case
	 when upc_or_ean_id is null and upc_code is not null then upc_code
	 when upc_or_ean_id is not null and upc_code is null then upc_or_ean_id 
	 when upc_or_ean_id is not null and upc_code is not null then upc_code 
	 when upc_or_ean_id is null and upc_code is null then ''
end[UPC]	 , class_id1, m.default_product_group
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid 
where class_id1 not in ('IPTCI','PTI', 'LMS')
order by default_product_group