use P21Sand	;
-- test insert 2101001451

select max(inventory_supplier_uid) from dbo.inventory_supplier 

INSERT INTO "inventory_supplier" ("supplier_id","division_id","upc_code","delete_flag",
"date_created","date_last_modified","last_maintained_by","list_price","supplier_sort_code",
"cost","manufacturing_class_id","backhaul_amount","backhaul_type","lead_time_days",
"inv_mast_uid","inventory_supplier_uid" ) VALUES (115718,115718,'80067525653','N',GETDATE(),
GETDATE(),'MGOLDYN-SQL',0.000000000,'CJ',2.324000000,'8483.90.1050 CN',0,'R',0,
1453,185618)

select inventory_supplier_uid[suid]
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where item_id = '2101001451' and supplier_id = 16013

select max(inventory_supplier_x_loc_uid) from dbo.inventory_supplier_x_loc

insert into  dbo.inventory_supplier_x_loc (inventory_supplier_x_loc_uid,
inventory_supplier_uid,location_id,primary_supplier,average_lead_time,row_status_flag,
date_created,date_last_modified,last_maintained_by,override_vmi_status_flag,
key_vmi_indicator_changed_flag,manual_lead_time)
values (774115582,185618,100,'Y',0,704,Getdate(),GETDATE(),
'MGOLDYN-SQL','N','N',210)   

update dbo.inventory_supplier_x_loc
set primary_supplier = 'N'
where inventory_supplier_uid = 1452 and location_id = 100

select item_id
from inv_mast
where inv_mast_uid = 1453