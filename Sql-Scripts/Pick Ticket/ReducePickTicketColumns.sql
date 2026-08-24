/*
	02/13/2020 remove unwanted columns per ralphs request, split print_date to date & time, add picket ticket cost
	dropping duplicate lines of some orders
	02/14/2020 - need to split all dates
	02/28/2020 add requested_date per Ralph, tested in P21Play
*/
/* 
-- last 60 days
select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],CONVERT(Time(0),c_ship_date)[c_ship_time],invoice_no,a.order_no,carrier_type_cd,loc,ship2_name,CONVERT(date,order_date)[order_date],CONVERT(Time(0),order_date)[order_time],location_id,
taker,third_party_billing_flag,approved,Expr1,projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
where order_date > DATEADD(day, -60,GetDate()) 
group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),requested_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,carrier_type_cd,loc,ship2_name,order_date,location_id,
taker,third_party_billing_flag,approved,Expr1,projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc
*/
--to the beginning of time for Open 300

select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],CONVERT(Time(0),c_ship_date)[c_ship_time],invoice_no,a.order_no,carrier_type_cd,loc,ship2_name,CONVERT(date,order_date)[order_date],CONVERT(Time(0),order_date)[order_time],location_id,
taker,third_party_billing_flag,approved,Expr1,projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),requested_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,carrier_type_cd,loc,ship2_name,order_date,location_id,
taker,third_party_billing_flag,approved,Expr1,projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc

