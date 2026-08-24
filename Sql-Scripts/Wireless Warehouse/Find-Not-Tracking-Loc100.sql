select im.item_id, im.item_desc, il.location_id, il.qty_on_hand, il.track_bins, il.stockable, il.delete_flag, im.delete_flag
from inv_loc il 
inner join inv_mast im on im.inv_mast_uid = il.inv_mast_uid
where (il.delete_flag = 'N' OR il.delete_flag is NULL)
and  ( im.delete_flag = 'N' OR im.delete_flag is NULL)
and  ( il.track_bins  =  'N' OR il.track_bins is NULL)
and  ( il.stockable   =  'N'  OR il.stockable is NULL)
and il.qty_on_hand   > 0  and location_id = 100

select im.item_id, im.item_desc, il.location_id, il.qty_on_hand, il.track_bins, il.stockable, il.delete_flag, im.delete_flag
from inv_loc il 
inner join inv_mast im on im.inv_mast_uid = il.inv_mast_uid
where ( il.track_bins  =  'N' OR il.track_bins is NULL)
and  ( il.stockable   =  'N'  OR il.stockable is NULL)
and il.qty_on_hand   > 0  and location_id = 100

