-- 07/29/22 -- Ralph phone call 410 only

select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],Route,Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],CONVERT(Time(0),c_ship_date)[c_ship_time],invoice_no,a.order_no,carrier_type_cd,loc,ship2_name,ship_2_state[SHIP TO STATE],CONVERT(date,order_date)[order_date],CONVERT(Time(0),order_date)[order_time],location_id,
taker,third_party_billing_flag,approved,Expr1,projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
where requested_date > '2022-07-17' and location_id = 410
group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),Route,requested_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,carrier_type_cd,loc,ship2_name,ship_2_state,order_date,location_id,
taker,third_party_billing_flag,approved,Expr1,projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc