select h.po_no[Customer Po No],h.customer_id,pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,
Convert(date,c_ship_date)[c_ship_date],CONVERT(Time(0),c_ship_date)[c_ship_time],a.invoice_no,a.order_no,carrier_type_cd,loc,a.ship2_name,CONVERT(date,a.order_date)[order_date],CONVERT(Time(0),a.order_date)[order_time],
a.location_id,a.taker,a.third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no
join oe_hdr h
on ol.order_no = h.order_no
where a.location_id = 410
group by h.po_no,h.customer_id,pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),a.requested_date,c_carrier,c_tracking_no,c_ship_date,a.invoice_no,a.order_no,carrier_type_cd,loc,a.ship2_name,a.order_date,a.location_id,
a.taker,a.third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions
order by pick_ticket_no desc