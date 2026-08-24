select distinct v.pick_ticket_no, v.tracking_no,v.delete_flag,t.tracking_no,t.delete_flag,t.order_no,t.carrier_id,v.carrier_name
from p21_view_clippership_return_10004 v
join oe_pick_ticket t
on v.pick_ticket_no = t.pick_ticket_no
where (t.delete_flag = 'Y' and v.delete_flag = 'N')
--where (t.delete_flag = 'N' and v.delete_flag = 'Y')
--where t.pick_ticket_no = 2094107 

--Exec p21_pick_ticket_cancel 2094107 -- test per Epicor, result: This Pick Ticket is not valid to cancel
/*
select distinct v.pick_ticket_no, v.tracking_no,v.delete_flag,t.tracking_no,t.delete_flag,t.order_no,t.carrier_id,v.carrier_name
from p21_view_clippership_return_10004 v
join oe_pick_ticket t
on v.pick_ticket_no = t.pick_ticket_no
where t.pick_ticket_no = 2094107 */