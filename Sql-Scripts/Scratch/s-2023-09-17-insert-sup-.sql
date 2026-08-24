select s.inventory_supplier_uid,s.supplier_id,ist.country_of_origin
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_trade ist
on s.inventory_supplier_uid = ist.inventory_supplier_uid
where  supplier_id in (46788,182518) and item_id = '2209221703'


select s.inventory_supplier_uid
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where  supplier_id = 182518 and item_id = '2209221703'


select *
from inventory_supplier_trade
where inventory_supplier_uid = 132309

select item_id,item_desc,s.inventory_supplier_uid,cost,manufacturing_class_id,coalesce(s.upc_code,0)[upc_code],list_price,
coalesce(supplier_sort_code,'')[supplier_sort_code],m.inv_mast_uid,coalesce(check_digit,0)check_digit
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where  supplier_id = 46788 and item_id = '2101100103'

INSERT INTO "inventory_supplier" ("supplier_id","division_id","upc_code","check_digit","delete_flag",
"date_created","date_last_modified","last_maintained_by","list_price","supplier_sort_code",
"cost","manufacturing_class_id","backhaul_amount","backhaul_type","lead_time_days",
"inv_mast_uid","inventory_supplier_uid" ) VALUES (182518,182518,'',,'N',GETDATE(),
GETDATE(),'MGOLDYN-SQL',,'',,'',0,'R',0,
,194067)

select *
from inv_mast
where inv_mast_uid = 106295

select m.inv_mast_uid,isu.upc_code,check_digit
from dbo.inv_mast  m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101100103' and isu.supplier_id = 46788
