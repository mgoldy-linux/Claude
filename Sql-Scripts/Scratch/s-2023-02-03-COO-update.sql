select ist.country_of_origin,m.inv_mast_uid,ist.inventory_supplier_uid,s.delete_flag,ist.inventory_supplier_trade_uid
    from dbo.inventory_supplier_trade ist
    join dbo.inventory_supplier s
	on s.inventory_supplier_uid = ist.inventory_supplier_uid
	join dbo.inv_mast m
    on s.inv_mast_uid = m.inv_mast_uid
    where m.item_id = '2208230548'
	
	
select m.inv_mast_uid,s.delete_flag,inventory_supplier_uid,supplier_id
from dbo.inventory_supplier s
join dbo.inv_mast m
on s.inv_mast_uid = m.inv_mast_uid
where m.item_id = '2208230548'    

Select *
from inventory_supplier_trade
where inventory_supplier_uid = 131853