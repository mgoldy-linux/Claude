use P21;

select item_id,class_id1
from dbo.inv_mast m
join dbo.inventory_supplier isu
on isu.inv_mast_uid = m.inv_mast_uid
where supplier_id = 46473 and m.delete_flag = 'N'