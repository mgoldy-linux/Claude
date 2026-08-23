with getPut
as
(
	select b.location_id, bin_id, bin_type,zone_desc[putaway_zone],putaway_zone_sequence,pick_zone_uid, pick_zone_sequence
	from dbo.bin b
	left join dbo.bin_type t
	on b.bin_type_uid = t.bin_type_uid
	left join dbo.bin_zone z
	on B.putaway_zone_uid = z.bin_zone_uid
	where delete_flag = 'N'
)
select distinct p.location_id, p.bin_id, bin_type,putaway_zone,putaway_zone_sequence,zone_desc[pick_zone], pick_zone_sequence,old_bin
from getPut p
left join dbo.bin_zone z
on p.pick_zone_uid = z.bin_zone_uid
left join dbo.bin_ud bu
on p.bin_id = bu.bin_id and p.location_id = bu.location_id
where p.location_id = 430

select *
from dbo.bin
where bin_id like 'No_%'

Use P21Play;

select *
from bin_type

select location_id,bin_id
from bin
where location_id = 430 and delete_flag = 'N'

use WQMetaData;
select top 5 *
from vwinventory

use p21;

select item_id,item_desc,class_id2,class_id5,l.location_id,stockable
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where item_id = '2101080928'  and stockable = 'Y'


select bin_id, bin_type_uid,pick_locked_flag,put_locked_flag,full_flag,frozen_flag,max_weight,current_weight,current_volume,putaway_zone_uid,putaway_zone_sequence,pick_zone_uid,pick_zone_sequence,warehouse_sequence,bin_length,bin_height,bin_width,bin_uid,rf_bin_flag,consolidation_bin_flag,stage_bin_flag,door_bin_flag,master_bin_flag,pick_confirmed_flag
from bin
where location_id = 430 and delete_flag = 'N'

select Location_id, bin_id
from bin
where location_id = 430 and delete_flag = 'N' and last_maintained_by = 'MGOLDYN'
