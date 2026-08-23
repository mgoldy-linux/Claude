select item_id[SIMG],item_desc,
case
when class_id1 = 'MD' then 'MASTERDRIVE'
else 'Missing'
end[BRAND],class_id5[PackType]
from dbo.inv_mast m
where class_id1 = 'MD'