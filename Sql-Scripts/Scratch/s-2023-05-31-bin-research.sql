update dbo.Bin
set pick_locked_flag = 'Y', pick_zone_uid = 72
where bin_id = 'ARM-001' and location_id = 100

select top 5 *
from bin_zone
where bin_zone = 'ARM-001'

select *
from dbo.Bin
where pick_zone_uid = 72 and location_id = 100 and bin_id = 'ARM-001' 

select *
from inv_bin 
where inv_bin_uid = 66472