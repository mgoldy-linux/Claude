use P21Sand;

-- get current counter
select  max(inventory_supplier_x_loc_uid)[max_isxl] from dbo.inventory_supplier_x_loc

-- current primary supplier
select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost,
manufacturing_class_id,average_lead_time,coalesce(manual_lead_time,210)[manual_lead_time],s.upc_code,list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where  supplier_id = 46788 and item_id = '2209221703'
order by item_desc

--check if 182518 in table for location
select m.inv_mast_uid,s.inventory_supplier_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where supplier_id = 182518 and location_id = 100 and item_id = '2209221703' 

-- get 182518 inventory_supplier_uid
select inventory_supplier_uid
from inventory_supplier 
where inv_mast_uid = 106113 and supplier_id = 182518

-- insert new location for 182518 - repeat for each location, turn on primary supplier 
insert into  dbo.inventory_supplier_x_loc (inventory_supplier_x_loc_uid,
inventory_supplier_uid,location_id,primary_supplier,average_lead_time,row_status_flag,
date_created,date_last_modified,last_maintained_by,override_vmi_status_flag,
key_vmi_indicator_changed_flag,manual_lead_time)
values (774214387,193822,100,'Y',0,704,Getdate(),GETDATE(),
'MGOLDYN-SQL','N','N',273)   

-- get primary supplier
select isxl.inventory_supplier_uid,isu.supplier_id
from dbo.inventory_supplier_x_loc isxl
join dbo.inventory_supplier isu
on isxl.inventory_supplier_uid = isu.inventory_supplier_uid
where primary_supplier = 'Y' and inv_mast_uid = 106113 and location_id = 100 and isxl.inventory_supplier_uid != 193822

-- turn off current primary 
update dbo.inventory_supplier_x_loc
set primary_supplier = 'N'
where inventory_supplier_uid = 132310 and location_id = 100

-- update counter
exec p21_set_counter @counter_id='inventory_supplier_x_loc',@counter_num = 774214387
