update dbo.inventory_supplier
set delete_flag = 'N'
where inv_mast_uid = 3050 and supplier_id = 47614

delete
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = 76773 and primary_supplier = 'N'

select *
from dbo.inventory_supplier_x_loc
where inventory_supplier_uid = 76773 and primary_supplier = 'N'

select  inventory_supplier_uid, *
from dbo.inventory_supplier
where inv_mast_uid = 3050 and supplier_id = 47614