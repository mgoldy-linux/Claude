-- 60 days
select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],
Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],
CONVERT(Time(0),c_ship_date)[c_ship_time],invoice_no,a.order_no,loc,bill2_name,a.ship2_name,CONVERT(date,a.order_date)[order_date],
CONVERT(Time(0),a.order_date)[order_time],a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
join p21_view_ord_ack_hdr b
on ol.order_no = b.order_no
where a.order_date > DATEADD(day, -60,GetDate())
group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),a.requested_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,
loc,bill2_name,a.ship2_name,a.order_date,a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc

-- all time
select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],Route,
Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],CONVERT(Time(0),c_ship_date)[c_ship_time],
invoice_no,a.order_no,carrier_type_cd,loc,bill2_name,a.ship2_name,ship_2_state[SHIP TO STATE],CONVERT(date,a.order_date)[order_date],
CONVERT(Time(0),a.order_date)[order_time],a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
join p21_view_ord_ack_hdr b
on ol.order_no = b.order_no
group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),Route,a.requested_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,
carrier_type_cd,loc,bill2_name,a.ship2_name,ship_2_state,a.order_date,a.location_id,
taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc


select top 5 *
from aaa_missing_pick_tickets
where pick_ticket_no > 2250005

select bill_to_id,*
from oe_hdr
where order_no = 1313882

select *
from oe_pick_ticket
where pick_ticket_no = 2250010

select top 5*
from oe_hdr
order by order_no desc

select *
from invoice_hdr
where order_no = '1319861'

select top 5 bill2_name,*
from p21_view_ord_ack_hdr
order by order_no desc