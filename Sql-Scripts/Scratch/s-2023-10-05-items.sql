select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,isxl.location_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid -- and l.location_id = 410
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where isu.supplier_id = 47614 and isu.delete_flag = 'N' and l.product_group_id != 'OTHERCHG'
order by item_id

select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,isxl.location_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid -- and l.location_id = 410
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where m.class_id1 = 'MD' and isu.delete_flag = 'N' and l.product_group_id != 'OTHERCHG'
order by item_id


select *
from inv_mast m
where date_created > '2023-09-01' and class_id2 = 'EPL'
order by date_created desc