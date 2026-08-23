select *
from oe_pick_ticket
where pick_ticket_no = 2128532

update oe_pick_ticket
set delete_flag = 'N'
where pick_ticket_no = 2128532

select delete_flag, tracking_no
from oe_pick_ticket
where pick_ticket_no = 2128532