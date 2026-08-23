--use P21Play;

select count(location_id)[numOfBefore]
from dbo.inv_loc il
join dbo.inv_mast  m
on il.inv_mast_uid = m.inv_mast_uid
where price_family_uid != m.default_price_family_uid


update il
set il.price_family_uid = m.default_price_family_uid
from dbo.inv_loc il
join dbo.inv_mast  m
on il.inv_mast_uid = m.inv_mast_uid

select count(location_id)[numOfAfter]
from dbo.inv_loc il
join dbo.inv_mast  m
on il.inv_mast_uid = m.inv_mast_uid
where price_family_uid != m.default_price_family_uid