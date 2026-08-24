select *
from E_Open_Pick_Ticket_VW

select pick_ticket_no,sum(ol.extended_price)[Order_Amt],Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],Route, Convert(date,a.requested_date)[requested_date],c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],CONVERT(Time(0),c_ship_date)[c_ship_time], invoice_no,a.order_no,carrier_type_cd,loc,bill2_name,a.ship2_name,ship_2_state[SHIP TO STATE],CONVERT(date,a.order_date)[order_date], CONVERT(Time(0),a.order_date)[order_time],a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions from aaa_missing_pick_tickets a left join oe_line ol on a.order_no = ol.order_no join p21_view_ord_ack_hdr b on ol.order_no = b.order_no where print_date > dateadd(day,datediff(day,60,GETDATE()),0) group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),Route,a.requested_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no, carrier_type_cd,loc,bill2_name,a.ship2_name,ship_2_state,a.order_date,a.location_id, taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions order by pick_ticket_no desc


select order_no, date_paid, *
from invoice_hdr
where invoice_no in  ('3501142','3506027','3507658','3491645','3492763','3501461','3498898')

select order_no,invoice_no
from invoice_line
where invoice_no in  ('3501142','3506027','3507658','3491645','3492763','3501461','3498898')


select invoice_no
from oe_hdr
where order_no in (1606270,1632427,1622358)

-- orginal from Hamza
select invoice_period, ih.invoice_no, ol.order_no, ol.line_no, amount_paid, il.extended_price, ih.invoice_date, gl_revenue_account_no from invoice_hdr ih
left join invoice_line il on il.invoice_no = ih.invoice_no
left join oe_line ol on  il.line_no = ol.line_no and il.order_no = ol.order_no
join oe_hdr oh
on ol.order_no = oh.order_no
where invoice_period = '2024009' --and ih.invoice_no = '3501142' 

select invoice_period, ih.invoice_no, ol.order_no, ol.line_no, amount_paid, il.extended_price, ih.invoice_date, gl_revenue_account_no from invoice_hdr ih
left join invoice_line il on il.invoice_no = ih.invoice_no
left join oe_line ol on  il.line_no = ol.line_no and il.order_no = ol.order_no
join oe_hdr oh
on ol.order_no = oh.order_no
where  ih.invoice_no = '3501142' 

-- my changes - invoice reference only
select  invoice_period, ih.invoice_no, amount_paid, ih.order_no, il.line_no, il.extended_price, ih.invoice_date, gl_revenue_account_no from invoice_hdr ih
left join invoice_line il
on il.invoice_no = ih.invoice_no
left join oe_line ol on  il.line_no = ol.line_no and il.order_no = ol.order_no
where invoice_period = '2024009'