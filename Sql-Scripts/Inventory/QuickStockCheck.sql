SELeCT il.inv_mast_uid, qty_on_hand,item_id
from inv_loc il
join inv_mast im
on il.inv_mast_uid = im.inv_mast_uid
where location_id = 350 and qty_on_hand > 0
order by qty_on_hand desc