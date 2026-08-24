select distinct primary_bin
from dbo.inv_loc
where location_id = 430

select count(primary_bin)
from dbo.inv_loc
where location_id = 430

select *
from dbo.inv_loc
where location_id = 430


select primary_bin
from dbo.inv_loc l
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
where location_id = 430 and item_id = '21039347'

Update l
Set primary_bin = '$primary_bin'
from dbo.inv_loc l
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
Where location_id = 430 and item_id = '$item_id'


-- after update
select item_id[SIMG],primary_bin
from dbo.inv_loc l
join dbo.inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
where location_id = 430 