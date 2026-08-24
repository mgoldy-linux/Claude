-- find COO for current supplier
select s.inventory_supplier_uid,s.supplier_id,ist.country_of_origin
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_trade ist
on s.inventory_supplier_uid = ist.inventory_supplier_uid
where  supplier_id = 182518 and item_id =  '2209221703'

-- get new inventory supplier uid
select s.inventory_supplier_uid
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where  supplier_id = 182518 and item_id =  '2209221703'

-- check if already thers
select *
from inventory_supplier_trade
where inventory_supplier_uid = 194018

select isxl.inventory_supplier_uid,isu.supplier_id
from dbo.inventory_supplier_x_loc isxl
join dbo.inventory_supplier isu
on isxl.inventory_supplier_uid = isu.inventory_supplier_uid
where primary_supplier = 'Y' and inv_mast_uid = 81092 and location_id = 100 and isxl.inventory_supplier_uid != 194060

select isxl.inventory_supplier_uid,isu.supplier_id
from dbo.inventory_supplier_x_loc isxl
join dbo.inventory_supplier isu
on isxl.inventory_supplier_uid = isu.inventory_supplier_uid
where primary_supplier = 'Y' and inv_mast_uid = 83988 and location_id = 100 and isxl.inventory_supplier_uid = 193470