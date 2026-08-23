-- oe Header
select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],
Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],
CONVERT(Time(0),c_ship_date)[c_ship_time],invoice_no,a.order_no,loc,bill2_name,a.ship2_name,CONVERT(date,a.order_date)[order_date],
CONVERT(Time(0),a.order_date)[order_time],a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
join p21_view_ord_ack_hdr b
on ol.order_no = b.order_no
where a.order_date > DATEADD(day, -30,GetDate()) and pick_ticket_no = 2493762
group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),a.requested_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,
loc,bill2_name,a.ship2_name,a.order_date,a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc

-- oe_line required date - 2493762
select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],
Convert(date,ol.required_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],
CONVERT(Time(0),c_ship_date)[c_ship_time],invoice_no,a.order_no,loc,bill2_name,a.ship2_name,CONVERT(date,a.order_date)[order_date],
CONVERT(Time(0),a.order_date)[order_time],a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
join p21_view_ord_ack_hdr b
on ol.order_no = b.order_no
where a.order_date > DATEADD(day, -30,GetDate())  and ol.complete = 'N' and ol.required_date < GETDATE() and ol.extended_price > 0 
group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),ol.required_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,
loc,bill2_name,a.ship2_name,a.order_date,a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc

select required_date,*
from oe_line
where order_no = 1605414 and delete_flag = 'N'