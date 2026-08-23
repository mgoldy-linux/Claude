use P21Sand;

select inventory_supplier_uid
from inventory_supplier 
where inv_mast_uid = 106113 and supplier_id = 182518

select *
from inv_mast 
where item_id = '2209221703'

-- get locations
select m.inv_mast_uid,s.inventory_supplier_uid,isxl.primary_supplier,isxl.inventory_supplier_x_loc_uid,s.supplier_id,isxl.location_id
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  item_id = '2101080796' and location_id = 100
-- check
select isxl.primary_supplier, supplier_id
from inventory_supplier s
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  inv_mast_uid = 81092 and location_id = 100 and isxl.inventory_supplier_x_loc_uid = 601564

select isxl.primary_supplier, supplier_id
from inventory_supplier s
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  inv_mast_uid = 81092 and location_id = 100 and isxl.inventory_supplier_x_loc_uid = 103899

