SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

select  distinct
a.loc[pick_loc],
Convert(date,ol.required_date)[requested_date],
a.pick_ticket_no,
Convert(date,a.print_date)[print_date],
CONVERT(Time(0),a.print_date)[print_time],
a.Route,
a.c_carrier,
a.c_tracking_no,
Convert(date,a.c_ship_date)[c_ship_date],
CONVERT(Time(0),a.c_ship_date)[c_ship_time],
a.invoice_no,
a.location_id[sales_loc],
CONVERT(date,a.order_date)[order_date],
a.order_no,
a.taker,
b.name [bill2_name],
a.ship2_name,
a.instructions
from aaa_missing_pick_tickets  a 
	left join oe_line ol on a.order_no = ol.order_no 
	inner join oe_hdr oh on ol.order_no = oh.order_no
	INNER JOIN address b ON b.id = oh.customer_id 
where  
a.print_date > dateadd(day,datediff(day,30,GETDATE()),0) 
and ol.complete != 'Y'