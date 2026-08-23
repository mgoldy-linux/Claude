select inventory_supplier_uid, s.delete_flag, m.inv_mast_uid
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where item_id = '2101112706' and s.supplier_id = 182518

update dbo.inventory_supplier 
set delete_flag = 'Y'
where inv_mast_uid = 104599  and supplier_id = 182518

Select delete_flag
from inventory_supplier 
where inv_mast_uid = 104599  and supplier_id = 182518