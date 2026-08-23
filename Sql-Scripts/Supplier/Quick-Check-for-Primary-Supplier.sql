select m.inv_mast_uid,s.inventory_supplier_uid,isxl.primary_supplier,isxl.inventory_supplier_x_loc_uid,s.supplier_id,isxl.location_id
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  item_id = '2101029783'

select item_id, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.location_id[to_loc],l.sellable,buy
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid 
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where item_id = '2101016939' and l.location_id = 300
