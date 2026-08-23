-- for larry
with get115718 
as
(
select item_id, s.inventory_supplier_uid,primary_supplier, location_id,supplier_id,m.inv_mast_uid
from dbo.inventory_supplier s
join dbo.inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where supplier_id = 115718 and item_desc not like 'M-%' and location_id not in (510,511,520) and primary_supplier = 'Y'
 ),
 get47614 
 as
 (
select item_id, s.inventory_supplier_uid,primary_supplier, location_id,supplier_id,m.inv_mast_uid
from dbo.inventory_supplier s
join dbo.inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where supplier_id = 47614 and item_desc not like 'M-%' and location_id not in (510,511,520) and primary_supplier = 'Y'
)
select distinct g4.supplier_id,g1.inv_mast_uid,g4.inventory_supplier_uid
from get115718 g1
join get47614 g4
on g1.item_id = g4.item_id and g1.location_id = g4.location_id and g1.inv_mast_uid = g4.inv_mast_uid
order by inv_mast_uid