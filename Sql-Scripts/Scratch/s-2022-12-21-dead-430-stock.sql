select m.item_id,m.item_desc,il.qty_on_hand,il.last_rec_po,m.weight, m.width,m.length,bore_diameter,outside_diameter,overall_width,overall_length,box_size,bag_size,usa_box_size,usa_bag_size
from dbo.inv_mast_ud u
join dbo.inv_mast m
on m.inv_mast_uid = u.inv_mast_uid
join dbo.inv_loc il
on il.inv_mast_uid = m.inv_mast_uid 
where item_id = '2101076968' and location_id = 410

/*
select *
from dbo.contacts

exec sp_who2
-- returns multiple SIMGs
select  *
from dbo.inv_mast_ud
where legacy_iteM_id = 'UCT207-22             T75CN'
*/