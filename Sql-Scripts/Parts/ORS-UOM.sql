select item_id, item_desc, u.unit_of_measure, unit_size, class_id1
from inv_mast m
join item_uom u
on m.inv_mast_uid = u.inv_mast_uid
where class_id1 = 'ORS'
order by item_id