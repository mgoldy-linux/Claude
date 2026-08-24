--Use play2;
--Use p21;

use P21Sand;


Select inv_mast_uid
from dbo.inv_mast 
where item_id = '2101027423'

select inventory_supplier_uid,*
from inventory_supplier 
where inv_mast_uid =  3050 --27425  --6148

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 50040 -- 40518


update dbo.inventory_supplier_x_loc
set primary_supplier = 'N'
where inventory_supplier_x_loc_uid = 51413 --41990

select *
from inventory_supplier_x_loc
where inventory_supplier_uid = 50040 -- 40518