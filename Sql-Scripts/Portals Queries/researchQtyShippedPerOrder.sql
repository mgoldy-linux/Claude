select item_id, (170 - sum(ship_quantity))[Qty_Remaining_To_ship]
from p21_view_support_sql_salesorder_oe_pick_ticket_detail
where pick_ticket_no in (2015818, 2016074,2025539,2035319,2055591)
group by item_id
/*
select *
from oe_pick_ticket_detail
where pick_ticket_no = 2015818

select *
from p21_view_alert_oe_Shipping
where pick_ticket_no = 2015818
*/

select * 
from oe_line
where order_no = 1013641