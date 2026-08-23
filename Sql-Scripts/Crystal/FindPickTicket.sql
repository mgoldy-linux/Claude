Use P21Crystal;

select pick_ticket_no,order_no
from oe_pick_ticket
where location_id = 200 and delete_flag = 'N'
order by print_date desc