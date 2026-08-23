update dbo.inventory_supplier
set delete_flag = 'Y'
where inv_mast_uid = 4624 and supplier_id = 47614

select inventory_supplier_uid,*
from inventory_supplier 
where inv_mast_uid = 3050

delete
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = 145343 and primary_supplier = 'N'