/*
Open Pick ticket View -- third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,sum(ol.extended_price)[Order_Amt],shipment_id,
*/
use P21Play; 
--use P21;
/*
if OBJECT_ID ('E_Open_Pick_Ticket_VW', 'V') is not null
drop view E_Open_Pick_Ticket_VW;
go

create view [dbo].[E_Open_Pick_Ticket_VW] AS
*/

select distinct loc[pick_loc],Convert(date,ol.required_date)[requested_date],pick_ticket_no,Convert(date,print_date)[print_date],CONVERT(Time(0),print_date)[print_time],Route,
c_carrier,c_tracking_no,Convert(date,c_ship_date)[c_ship_date],CONVERT(Time(0),c_ship_date)[c_ship_time],invoice_no,a.location_id[sales_loc],CONVERT(date,a.order_date)[order_date],a.order_no,
taker,bill2_name,a.ship2_name,instructions
from aaa_missing_pick_tickets  a
left join oe_line ol
on a.order_no = ol.order_no 
join p21_view_ord_ack_hdr b
on ol.order_no = b.order_no
where a.order_date > DATEADD(day, -30,GetDate())  and ol.complete = 'N'  
/*group by pick_ticket_no,Convert(date,print_date),CONVERT(Time(0),print_date),ol.required_date,c_carrier,c_tracking_no,c_ship_date,invoice_no,a.order_no,
loc,bill2_name,a.ship2_name,a.order_date,a.location_id,taker,third_party_billing_flag,a.approved,Expr1,a.projected_order,a.cancel_flag,shipment_id,instructions*/
--order by requested_date desc
go

/*
grant select on object::E_Open_Pick_Ticket_VW to p21_application_role
grant select on object::E_Open_Pick_Ticket_VW to PxxiUser
grant select on object::E_Open_Pick_Ticket_VW to [PTIDOM\P21Users]
*/
