select *
from Inventory_supplier_trade 
where inventory_supplier_uid in (16013, 115718)

select ist.country_of_origin,m.inv_mast_uid,ist.inventory_supplier_uid,s.delete_flag,ist.inventory_supplier_trade_uid
from dbo.inventory_supplier_trade ist
join dbo.inventory_supplier s
on s.inventory_supplier_uid = ist.inventory_supplier_uid
join dbo.inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
where m.item_id = '2101003018'

select top 5*
from Inventory_supplier_trade 
where inventory_supplier_uid = 185622
order by date_created desc

select *
from inv_mast
where item_id = '2101001148'

select *
from inventory_supplier
where inv_mast_uid = 1150