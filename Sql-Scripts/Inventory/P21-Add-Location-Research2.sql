-- query to check for missing data
select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id,isu.supplier_id,isxl.primary_supplier
from dbo.inv_loc l
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where item_id = '2100039247' and l.location_id = 410