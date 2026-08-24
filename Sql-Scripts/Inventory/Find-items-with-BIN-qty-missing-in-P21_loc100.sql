select il.qty_on_hand - sum(ib.quantity)[Qty-Missing-From-BIN],item_id	,il.primary_bin, il.qty_allocated	,il.location_id, track_bins,il.inv_mast_uid
from dbo.inv_loc il
join dbo.inv_mast m
on m.inv_mast_uid = il.inv_mast_uid
left join inv_bin ib
on ib.inv_mast_uid = il.inv_mast_uid and ib.location_id = il.location_id
where	COALESCE(il.track_bins, 'N') = 'Y' AND COALESCE(il.lot_bin_integration, 'N') = 'N'    AND m.use_tags_flag = 'N' and il.location_id = 100
group by m.item_id,	il.qty_on_hand ,il.primary_bin, il.qty_allocated,il.location_id,track_bins,il.inv_mast_uid
having il.qty_on_hand > sum(ib.quantity)
order by inv_mast_uid

--exec p21_rebuild_singular_bin 2101007223, 100

--exec p21_rebuild_primary_bin 2101007223, 100