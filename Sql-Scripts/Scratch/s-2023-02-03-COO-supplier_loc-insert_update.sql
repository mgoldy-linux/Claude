select s.inventory_supplier_uid,primary_supplier,location_id
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where item_id = '2101063969' and supplier_id = 46627

select s.inventory_supplier_uid,primary_supplier,location_id
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where item_id = '2101063969' and supplier_id = 58991 and primary_supplier = 'Y'

select s.inventory_supplier_uid,primary_supplier,location_id
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where item_id = '2101063969' and supplier_id = 47391 and primary_supplier = 'Y'

select inventory_supplier_x_loc_uid, location_id, primary_supplier
from inventory_supplier_x_loc
where inventory_supplier_uid = 86853 

update dbo.inventory_supplier_x_loc
set primary_supplier = 'N'
where inventory_supplier_uid = 86853