-- SIMG, Default Product Group, Legacy Item Desc, Legacy Item ID, UPC

select m.default_product_group,extended_desc,item_desc, item_id[select_item_id],
case
	when m.upc_or_ean_id is null then concat(si.upc_code,si.check_digit)
	when si.upc_code is null then m.upc_or_ean_id
	else concat(si.upc_code,si.check_digit)
end[UPC]
from dbo.inv_mast m
join dbo.inventory_supplier si
on m.inv_mast_uid = si.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where m.delete_flag = 'N' and l.location_id = 300