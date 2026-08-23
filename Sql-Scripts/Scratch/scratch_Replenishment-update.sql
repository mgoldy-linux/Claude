select replenishment_method,safety_stock_type, *
from inv_loc
where inv_mast_uid = 104942

select inv_mast_uid
from inv_mast
where item_id = '2101103033'