select top 5 m.item_desc, a.*
from dbo.inv_bin_audit a
join dbo.inv_mast m
on a.inv_mast_uid = m.inv_mast_uid
where location_id = 100

select top 5 *
from bin
where  bin_uid = 90925