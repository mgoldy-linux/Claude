use [P21Play]
go

-- number of missing upcs from inventory_supplier
select count(im.upc_or_ean_id)[# missing upc]
from inventory_supplier ivs
join inv_mast im
on ivs.inv_mast_uid = im.inv_mast_uid
where upc_code is null and im.upc_or_ean_id is not null and im.class_id2 = 'EPL'

-- update
update inventory_supplier
set inventory_supplier.upc_code = inv_mast.upc_or_ean_id, inventory_supplier.check_digit = (select * from dbo.CalculateCheckDigitUPC(inv_mast.upc_or_ean_id))
from inventory_supplier, inv_mast
where inventory_supplier.inv_mast_uid = inv_mast.inv_mast_uid

-- check results
select * -- ivs.upc_code,ivs.check_digit,ivs.inv_mast_uid,ivs.date_last_modified
from inventory_supplier ivs
where ivs.inv_mast_uid = 4672
order by ivs.date_last_modified desc