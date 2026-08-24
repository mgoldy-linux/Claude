select legacy_item_id, legacy_item_description 
from inv_mast_ud
where legacy_item_description = 'NPPX 06'
--where inv_mast_uid = 31486


select item_id, item_desc, class_id1,class_id2, MU.legacy_item_id, MU.legacy_item_description
from inv_mast m
join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where item_id like '210103262%'

select si.upc_code,short_code,item_id, item_desc, class_id1,class_id2, MU.legacy_item_id, MU.legacy_item_description
from inv_mast m
join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
join inventory_supplier si
on m.inv_mast_uid = si.inv_mast_uid
where item_desc like 'PA206%'