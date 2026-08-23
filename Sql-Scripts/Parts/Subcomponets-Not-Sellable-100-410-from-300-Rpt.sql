with getComponetUIDs 
as
(
select distinct al.component_inv_mast_uid
from dbo.assembly_hdr ah
join dbo.inv_mast m
on ah.inv_mast_uid = m.inv_mast_uid
join dbo.assembly_line al
on al.inv_mast_uid = ah.inv_mast_uid
where bypass_oe_prod_order_processing = 'Y' and m.delete_flag = 'N'
),
at300
as
(
select item_id, item_desc, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,l.sellable[sellable300],discontinued
from getComponetUIDs gc
join dbo.inv_mast m
on m.inv_mast_uid = gc.component_inv_mast_uid
left join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid 
left join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where isxl.location_id = 300 and primary_supplier = 'Y' and discontinued = 'N' and class_id2 != 'EPL' 
),
at100
as
(
select item_id, item_desc, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,discontinued,l.sellable[sellable100]
from getComponetUIDs gc
join dbo.inv_mast m
on m.inv_mast_uid = gc.component_inv_mast_uid
left join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid 
left join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where isxl.location_id = 100 and primary_supplier = 'Y' and discontinued = 'N' and class_id2 != 'EPL' 
),
at410
as
(
select item_id, item_desc, m.inv_mast_uid,l.product_group_id,isu.manufacturing_class_id, isu.supplier_id,isxl.primary_supplier,discontinued,l.sellable[sellable410]
from getComponetUIDs gc
join dbo.inv_mast m
on m.inv_mast_uid = gc.component_inv_mast_uid
left join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid 
left join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid 
left join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid and l.location_id = isxl.location_id
where isxl.location_id = 410 and primary_supplier = 'Y' and discontinued = 'N' and class_id2 != 'EPL' 
)
select a3.item_id,a3.item_desc, isnull(a1.sellable100,'N')[sellable100],a3.sellable300,isnull(a4.sellable410,'N')[sellable410]
from at300 a3
left join at410 a4
on  a3.inv_mast_uid = a4.inv_mast_uid
left join at100 a1
on  a3.inv_mast_uid = a1.inv_mast_uid
where a4.item_id is null or a1.item_id is null	


/*
select a3.*
from at300 a3
left join at100 a1
on  a3.inv_mast_uid = a1.inv_mast_uid
where a1.item_id is null


select a3.*
from at300 a3
left join at100 a1
on  a3.inv_mast_uid = a1.inv_mast_uid
where a3.item_id is null
order by item_id
*/