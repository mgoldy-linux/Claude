

select lo.*
from dbo.inv_mast m
join dbo.inv_loc lo
on m.inv_mast_uid = lo.inv_mast_uid
where m.item_id = '2101032582'

exec p21_rebuild_inventory_issues '2101032582',300
exec p21_rebuild_inv_loc_stock_status '20101032582',300
exec p21_rebuild_order_quantity 32584,300
exec p21_rebuild_singular_bin '2101032582',300


select lo.qty_on_hand,lo.qty_allocated,ilss.*
from dbo.inv_mast m
join dbo.inv_loc lo
on m.inv_mast_uid = lo.inv_mast_uid
join dbo.inv_loc_stock_status ilss
on m.inv_mast_uid = ilss.inv_mast_uid and lo.location_id = ilss.location_id
where m.item_id = '2101032582'  and lo.location_id = 300

select *
from inv_bin
where inv_mast_uid = 32584

select trans_type, document_no[Trans No],date_created,last_maintained_by,quantity,on_hand_before_trans
from dbo.inv_tran
where inv_mast_uid = 32584
order by date_created desc