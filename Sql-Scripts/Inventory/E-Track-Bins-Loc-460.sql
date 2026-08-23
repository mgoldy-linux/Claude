use P21;

select item_id[SIMG#], item_desc,track_bins,bin,quantity,extended_desc
from dbo.inv_loc l
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
left join dbo.inv_bin b
on b.inv_mast_uid = l.inv_mast_uid and b.location_id = l.location_id
where l.location_id = 460 and m.delete_flag = 'N'

