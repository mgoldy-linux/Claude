use P21Play;

-- Check Current
select distinct item_id, item_desc, extended_desc, upc_or_ean_id, upc_code
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_desc like 'T-%'


-- set inv_mast.upc_or_ean_id to null
update dbo.inv_mast
set upc_or_ean_id = NULL
where item_desc like 'T-%'

-- set inventory.upc_code to null
Update isu
set upc_code = NULL
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_desc like 'T-%'

-- check after update
select distinct item_id, item_desc, extended_desc, upc_or_ean_id, upc_code
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_desc like 'T-%'