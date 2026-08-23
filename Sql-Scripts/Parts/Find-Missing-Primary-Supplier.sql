
with getNoPri
as
(
select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.location_id[to_loc],l.sellable,discontinued
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid 
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where isxl.location_id = 300 and primary_supplier = 'N' and discontinued = 'N' and class_id2 = 'EPL' and class_id3 = 'ALL' --and item_id = '2101029783'
),
getPri
as
(
select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.location_id[to_loc],l.sellable,discontinued
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid 
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where isxl.location_id = 300 and primary_supplier = 'Y' and discontinued = 'N' and class_id2 = 'EPL' and class_id3 = 'ALL' --and item_id = '2101069367'
)
select gf.*
from getNoPri gf
left join getPri gt
on  gf.inv_mast_uid = gt.inv_mast_uid
where gt.item_id is null --and gf.item_id = '2101029783'