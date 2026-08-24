select item_id, item_desc, qty_on_hand
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where location_id = 601