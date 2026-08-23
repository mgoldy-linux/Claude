select item_id, item_desc, class_id1, class_id2, class_id3, l.location_id,l.sellable,l.discontinued,l.stockable,l.delete_flag,qty_on_hand
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where item_id in ('2101071887','2404041417') and l.location_id not in (150,350,440,603,605) -- '2101045042'

select *
from location
where delete_flag = 'N'


select inv_mast_uid,*
from inv_loc l
where location_id = 440 and qty_on_hand > 0


select *
from inv_mast
where inv_mast_uid = 7808