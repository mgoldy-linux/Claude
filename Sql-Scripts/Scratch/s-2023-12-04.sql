use P21Sand;

select *
from oe_hdr
where order_no = '1003759'

exec sp_help inventory_supplier

select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost,
manufacturing_class_id,average_lead_time,s.upc_code,list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where supplier_id = 47439 and item_id = '2101097096'

INSERT INTO "inventory_supplier" ("supplier_id","division_id","upc_code","check_digit","delete_flag","date_created","date_last_modified","last_maintained_by","list_price","supplier_sort_code","cost","manufacturing_class_id","backhaul_amount","backhaul_type","lead_time_days","inv_mast_uid","inventory_supplier_uid","effective_date" ) VALUES (46620,46620,'',0,'N',GETDATE(),GETDATE(),'MGOLDYN-SQL',2.2,'',2.2,'',0,'R',0,105424,195165,'2023-11-27')

select item_id,item_desc,s.inventory_supplier_uid,cost,manufacturing_class_id,coalesce(s.upc_code,'')[upc_code],list_price,
m.inv_mast_uid,coalesce(check_digit,0)check_digit
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where supplier_id = 47439 and item_id = '2101092712'

INSERT INTO "inventory_supplier" ("supplier_id","division_id","upc_code","check_digit","delete_flag","date_created","date_last_modified","last_maintained_by","list_price","supplier_sort_code","cost","manufacturing_class_id","backhaul_amount","backhaul_type","lead_time_days","inv_mast_uid","inventory_supplier_uid","effective_date" ) VALUES (182518,182518,'88856912982',6,'N',GETDATE(),GETDATE(),'MGOLDYN-SQL',6.25,'CZBR HP',6.25,'8483.20.4040 CN',0,'R',0,95101,195999,'2023-11-27')

INSERT INTO "inventory_supplier" ("supplier_id","division_id","upc_code","check_digit","delete_flag","date_created","date_last_modified","last_maintained_by","list_price","supplier_sort_code","cost","manufacturing_class_id","backhaul_amount","backhaul_type","lead_time_days","inv_mast_uid","inventory_supplier_uid","effective_date" ) VALUES (182518,182518,'88856912983',3,'N',GETDATE(),GETDATE(),'MGOLDYN-SQL',7.777777778,'CZBR HP',7.777777778,'8483.20.4040 CN',0,'R',0,95102,196000,'2023-11-27')

select item_id,item_desc,s.inventory_supplier_uid,primary_supplier,location_id,cost,manufacturing_class_id,average_lead_time,s.upc_code,list_price,coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on s.inventory_supplier_uid = isxl.inventory_supplier_uid
where supplier_id = 47439 and item_id = '2100039105'

select *
from inv_mast
where item_id in ('2101103043','2101092712')