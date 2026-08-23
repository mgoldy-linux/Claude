use P21Play;

select qty_on_hand,il.inv_mast_uid,item_id, il.*
from inv_loc il
join inv_mast im
on il.inv_mast_uid = im.inv_mast_uid
where location_id = 350 and class_id2 = 'EPL' and purchase_discount_group = 'PTI'
order by il.qty_on_hand desc