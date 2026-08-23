use P21Play;

select price_family_uid,m.default_price_family_uid
from dbo.inv_loc il
join dbo.inv_mast  m
on il.inv_mast_uid = m.inv_mast_uid
where item_id = '2101085219'

update il
set il.price_family_uid = m.default_price_family_uid
from dbo.inv_loc il
join dbo.inv_mast  m
on il.inv_mast_uid = m.inv_mast_uid
where item_id = '2101085219'

select price_family_uid,m.default_price_family_uid
from dbo.inv_loc il
join dbo.inv_mast  m
on il.inv_mast_uid = m.inv_mast_uid
where item_id = '2101085219'