Use P21Sand;
/*
select item_id, s.inventory_supplier_uid,primary_supplier, location_id,supplier_id, m.inv_mast_uid
from dbo.inventory_supplier s
join dbo.inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where supplier_id = 115718 and item_desc not like 'M-%' and location_id not in (510,511,520) and primary_supplier = 'Y'
*/
-- find double primary suppliers
with getids 
as
(
select m.inv_mast_uid, item_id, location_id
from dbo.inventory_supplier s
join dbo.inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where supplier_id = 115718 and item_desc not like 'M-%' and location_id not in (510,511,520) and primary_supplier = 'Y'
)
select item_id,isxl.location_id,s2.supplier_id,isxl.inventory_supplier_uid
from getids g
join dbo.inventory_supplier s2
on g.inv_mast_uid = s2.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s2.inventory_supplier_uid = isxl.inventory_supplier_uid and g.location_id = isxl.location_id
where supplier_id != 115718 and primary_supplier = 'Y' 