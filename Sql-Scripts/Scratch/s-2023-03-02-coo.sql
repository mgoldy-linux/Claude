use P21;

select item_id, country_of_origin
from dbo.inventory_supplier isu
join dbo.inv_mast m
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_trade ist
on isu.inventory_supplier_uid = ist.inventory_supplier_uid
where supplier_id = 46627 and m.delete_flag =  'N'
order by item_id 

select item_id,supplier_id,inventory_supplier_uid
from dbo.inventory_supplier isu
join dbo.inv_mast m
on m.inv_mast_uid = isu.inv_mast_uid
where item_id = '2101059782'

select *
from dbo.inventory_supplier_trade
where inventory_supplier_uid = 130139

exec p21_outlook_get_contacts