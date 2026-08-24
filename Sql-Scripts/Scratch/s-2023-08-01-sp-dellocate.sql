exec p21_deallocate_location_bin_transactions 410

exec p21_deallocate_pick_ticket 2231672

select *
from oe_pick_ticket 
where location_id = 410 and tracking_no is null

exec p21_unallocate_orders 410

exec p21_cancel_pick_ticket 2231672,C