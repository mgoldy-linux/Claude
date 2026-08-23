select m.inv_mast_uid,L.track_bins,quantity[Bin Qty],qty_on_hand,track_bins
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join inv_bin b
on l.inv_mast_uid = b.inv_mast_uid and l.location_id = b.location_id 
where item_id = '09067 [CONE]'

select *
from inv_bin
where inv_mast_uid = 15 and location_id = 200

Update inv_bin
set quantity = 0 
WHERE inv_mast_uid = 15 and location_id = 200

select m.inv_mast_uid,L.track_bins,quantity[Bin Qty],qty_on_hand,track_bins
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
join inv_bin b
on l.inv_mast_uid = b.inv_mast_uid and l.location_id = b.location_id 
where item_id = '09067 [CONE]'

select *
from inv_bin
where inv_mast_uid = 15 and location_id = 200

Select *
from inv_bin_audit
where inv_mast_uid = 15 and location_id = 200