
select ins.upc_code,ins.check_digit,im.item_id,im.short_code
from inventory_supplier ins
join inv_mast im
on ins.inv_mast_uid = im.inv_mast_uid
where upc_code = '78247500012'