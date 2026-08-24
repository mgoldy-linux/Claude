Select isu.inv_mast_uid, supplier_id,manufacturing_class_id,item_id
from inventory_supplier isu
join inv_mast m
on isu.inv_mast_uid = m.inv_mast_uid
where manufacturing_class_id not like '%.%' and manufacturing_class_id not in ('NON-INVENTORY','N/A','NON-INVENTORY CN') and manufacturing_class_id != ' '


select item_id,item_desc
from inv_mast
where item_id not like '2%' and delete_flag = 'N'

select item_id
from dbo.inv_mast m
where inv_mast_uid = '97097'

select distinct supplier_id
from dbo.inventory_supplier si
where manufacturing_class_id is null or supplier_id != 69814

select m.inv_mast_uid
from dbo.inventory_supplier si
join dbo.inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where supplier_id = 69814 and manufacturing_class_id is null  

select distinct manufacturing_class_id
from dbo.inventory_supplier si
where inv_mast_uid = 113075 and len(manufacturing_class_id) != 0 and manufacturing_class_id not in ('.. CN','0000.00.0000','.. XX')