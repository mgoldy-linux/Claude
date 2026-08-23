Use P21Sand;
-- find current JHIT - after adding AMAS suplier
select item_id,item_desc,s.inventory_supplier_uid,s.upc_code,list_price,m.inv_mast_uid,check_digit
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where  supplier_id in (16013,115718) and item_desc not like 'M-%' and supplier_id = 115718 --and item_id = '2101003659'
order by item_desc

select * 
from inventory_supplier
where inv_mast_uid = 1134

select top 5 *
from inventory_supplier_trade
where inventory_supplier_uid = 185661

exec sp_help inventory_supplier_trade

insert into "inventory_supplier_trade" ("inventory_supplier_trade_uid",
"inventory_supplier_uid","date_created","created_by","date_last_modified",
"last_maintained_by","country_of_origin")
values (1,185618,GetDate(),'mgoldyn-sql',Getdate(),
'mgoldyn-sql','CN')