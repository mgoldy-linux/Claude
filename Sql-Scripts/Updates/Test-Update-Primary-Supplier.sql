-- get inv_mast_uid
select inv_mast_uid
from dbo.inv_mast 
where item_id = '2101100646'

-- get 182518 inventory_supplier_uid
select inventory_supplier_uid
from inventory_supplier 
where inv_mast_uid = 101240 and supplier_id = 182518

-- get current Pri Supplier
select isxl.inventory_supplier_uid,isu.supplier_id
from dbo.inventory_supplier_x_loc isxl
join dbo.inventory_supplier isu
on isxl.inventory_supplier_uid = isu.inventory_supplier_uid
where primary_supplier = 'Y' and inv_mast_uid = $101240 and location_id = 100 and isxl.inventory_supplier_uid != 193456

-- turn off cuurent pri
update dbo.inventory_supplier_x_loc
set primary_supplier = 'N'
where inventory_supplier_uid = 124318 and location_id = 100

-- turn on pri for 182518 
update dbo.inventory_supplier_x_loc
set primary_supplier = 'Y'
where inventory_supplier_uid = 193456 and location_id = 100
