-- Turn off Primary Supplier
select Supplier_id,isxl.inventory_supplier_x_loc_uid,primary_supplier,location_id,s.inv_mast_uid,isxl.row_status_flag
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isxl.inventory_supplier_uid = s.inventory_supplier_uid
where item_id = '2101021481' and supplier_id = 47614

Update dbo.inventory_supplier_x_loc
set primary_supplier = 'N', row_status_flag = 700
where inventory_supplier_x_loc_uid in (496885,496886,496887,496888,496889,496890,496891)

select Supplier_id,isxl.inventory_supplier_x_loc_uid,primary_supplier,location_id,isxl.row_status_flag
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isxl.inventory_supplier_uid = s.inventory_supplier_uid
where item_id = '2101021481' and supplier_id = 47614

-- set supplier delete flag to 'Y'
select *
from inventory_supplier
where inv_mast_uid = 21483

update dbo.inventory_supplier
set delete_flag = 'Y'
where inv_mast_uid = 21483 and supplier_id = 47614

select *
from inventory_supplier
where inv_mast_uid = 21483

