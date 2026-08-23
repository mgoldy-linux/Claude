select m.inv_mast_uid,L.track_bins,quantity[Bin Qty],qty_on_hand,track_bins
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join inv_bin b
on l.inv_mast_uid = b.inv_mast_uid and l.location_id = b.location_id 
where item_id = '09067 [CONE]'

update inv_loc
set track_bins = 'Y'
where inv_mast_uid = 15

select m.inv_mast_uid,L.track_bins,quantity[Bin Qty],qty_on_hand,track_bins
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join inv_bin b
on l.inv_mast_uid = b.inv_mast_uid and l.location_id = b.location_id 
where item_id = '09195 [CUP]'

update inv_loc
set track_bins = 'N'
where inv_mast_uid = 15

select m.inv_mast_uid,L.track_bins,quantity[Bin Qty],qty_on_hand,track_bins
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
left join inv_bin b
on l.inv_mast_uid = b.inv_mast_uid and l.location_id = b.location_id 
where item_id = '09067 [CONE]'