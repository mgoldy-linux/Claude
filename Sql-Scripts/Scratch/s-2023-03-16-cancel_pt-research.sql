exec p21_cancel_pick_ticket_to_inv 2335378, 1

Select *
FROM	cancel_pick_ticket_lot 

Select *
FROM	cancel_pick_ticket_bin

Select *
FROM	cancel_pick_ticket_serial

Select *
FROM	cancel_pick_ticket_item


select distinct disposition
from oe_line

exec p21_cancel_pick_ticket 2335378,S

DELETE
	FROM	cancel_pick_ticket_bin

exec p21_pick_ticket_cancel 2335378