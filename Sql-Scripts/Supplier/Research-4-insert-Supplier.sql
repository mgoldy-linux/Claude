Use P21Sand;
-- find current JHIT - after adding AMAS suplier
select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost,
manufacturing_class_id,average_lead_time,coalesce(manual_lead_time,210)[manual_lead_time],s.upc_code,list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid,check_digit
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id in (16013,115718) and item_desc not like 'M-%' --and item_id = '2101003659'
order by item_desc

-- check if 115718 is here
select m.inv_mast_uid,s.inventory_supplier_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id = 115718 and location_id = 430 and item_id = '2101001132'

select inventory_supplier_uid
from inventory_supplier 
where inv_mast_uid = 1134 and supplier_id = 115718


-- Test insert
insert into  dbo.inventory_supplier_x_loc (inventory_supplier_x_loc_uid,
inventory_supplier_uid,location_id,primary_supplier,average_lead_time,row_status_flag,
date_created,date_last_modified,last_maintained_by,override_vmi_status_flag,
key_vmi_indicator_changed_flag,manual_lead_time)
values (774115582,192964,430,'Y',0,704,Getdate(),GETDATE(),
'MGOLDYN-SQL','N','N',210)   

select *
from inventory_supplier 
where inventory_supplier_uid = 192964

select *
from inventory_supplier_x_loc
where inventory_supplier_x_loc_uid = 774115582

select *
from inv_mast
where inv_mast_uid = 30326

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 192964

update dbo.inventory_supplier_x_loc
set primary_supplier = 'N'
where inventory_supplier_uid = 30325 and location_id = 430

select distinct manual_lead_time
from inventory_supplier_x_loc