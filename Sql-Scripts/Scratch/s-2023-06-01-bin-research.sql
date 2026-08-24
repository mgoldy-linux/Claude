select il.qty_on_hand,m.inv_mast_uid,ilss.*
from dbo.inv_loc il
join dbo.inv_mast m
on il.inv_mast_uid = m.inv_mast_uid
join inv_loc_stock_status ilss
on il.inv_mast_uid = ilss.inv_mast_uid
where item_id = '2101011174'

select *
from dbo.bin
where bin_id = 'ARM-001'

select item_id,quantity[InBin],bin,qty_non_pickable,il.qty_on_hand
from dbo.inv_bin ib
join dbo.inv_mast m
on ib.inv_mast_uid = m.inv_mast_uid
join inv_loc_stock_status ilss
on m.inv_mast_uid = ilss.inv_mast_uid
join dbo.inv_loc il
on il.inv_mast_uid = m.inv_mast_uid
where bin  = 'ARM-001'