select top 5 *
from dbo.inventory_supplier
order by inventory_supplier_uid desc 

select *
from inv_mast 
where inv_mast_uid = 1398

select m.inv_mast_uid,s.inventory_supplier_uid,primary_supplier,location_id
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id = 115718 and  item_id = '2101001132' 

-- check for supplier 
select m.inv_mast_uid,s.inventory_supplier_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where  supplier_id = 115718 and  item_id = '2101001396' 

select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost,
manufacturing_class_id,average_lead_time,manual_lead_time,s.upc_code,list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id = 16013 and primary_supplier = 'Y' and item_desc not like 'M-%'
order by item_desc


select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost,
manufacturing_class_id,average_lead_time,manual_lead_time,s.upc_code,list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id = 16013 and item_desc not like 'M-%'
order by item_desc

select m.inv_mast_uid,s.inventory_supplier_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where  supplier_id = 115718 and item_id = '2101001132' 

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 185619

insert into  dbo.inventory_supplier_x_loc (inventory_supplier_x_loc_uid,
inventory_supplier_uid,location_id,primary_supplier,average_lead_time,row_status_flag,
date_created,date_last_modified,last_maintained_by,override_vmi_status_flag,
key_vmi_indicator_changed_flag,manual_lead_time)
values (774115890,185926,410,'Y',0,704,Getdate(),GETDATE(),
'MGOLDYN-SQL','N','N',210)   

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 185926