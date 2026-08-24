select item_id, u.legacy_item_id,u.legacy_item_description
from dbo.inv_mast m
join dbo.inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid
where item_id = '2101052524'