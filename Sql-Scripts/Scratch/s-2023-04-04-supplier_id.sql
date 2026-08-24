use [P21Play2021.1.4420Local];

select isu.supplier_id, s.supplier_name,loc_cost,u.pack_type,u.carton_size,u.carton_qty,pack_notes_1,pack_notes_2,pack_notes_3,pack_notes_4,pack_notes_5
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
join dbo.supplier s
on isu.supplier_id = s.supplier_id
join dbo.inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid
where item_id = '2101062781' and location_id = 410 and primary_supplier = 'Y'


select *
from dbo.inv_mast_ud
where inv_mast_uid = 53910
select  *
from inventory_supplier
where inv_mast_uid = 53910

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 78157 and location_id = 410

select *
from supplier
where supplier_id = 47439