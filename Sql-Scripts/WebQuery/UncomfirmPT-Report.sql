use  WQMetaData;

-- ALL
select u.location_id[Location],u.customer_id[Customer ID],bill2_name[Customer_Name],pick_ticket_no[Pick Ticket #],tracking_no[Tracking #],format(print_date,'MM/dd/yyyy')[Print Date],format(order_date,'MM/dd/yyyy')[Order Date],format(Requested_Date,'MM/dd/yyyy')[Request_Date],format(ship_date,'MM/dd/yyyy')[Ship Date],order_no[Order Date],oe_line_no[OE Line #], format(unit_price,'C')[Unit Price],format(qty_ordered,'N')[Qty to Ship],format(OpenSales,'C')[Open $]
from dbo.vwUnconfirmed_Pick_Ticket u
join dbo.vwOpenOrders_fr o
on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum

-- 100/150
select u.location_id[Location],u.customer_id[Customer ID],bill2_name[Customer_Name],pick_ticket_no[Pick Ticket #],tracking_no[Tracking #],format(print_date,'MM/dd/yyyy')[Print Date],format(order_date,'MM/dd/yyyy')[Order Date],format(Requested_Date,'MM/dd/yyyy')[Request_Date],format(ship_date,'MM/dd/yyyy')[Ship Date],order_no[Order Date],oe_line_no[OE Line #], format(unit_price,'C')[Unit Price],format(qty_ordered,'N')[Qty to Ship],format(OpenSales,'C')[Open $]
from dbo.vwUnconfirmed_Pick_Ticket u
join dbo.vwOpenOrders_fr o
on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
where u.location_id in (100,150)
--where order_no = 1321949 --and unit_price != 0
--where order_date > '2022-09-09' 

-- 200
select u.location_id[Location],u.customer_id[Customer ID],bill2_name[Customer_Name],pick_ticket_no[Pick Ticket #],tracking_no[Tracking #],format(print_date,'MM/dd/yyyy')[Print Date],format(order_date,'MM/dd/yyyy')[Order Date],format(Requested_Date,'MM/dd/yyyy')[Request_Date],format(ship_date,'MM/dd/yyyy')[Ship Date],order_no[Order Date],oe_line_no[OE Line #], format(unit_price,'C')[Unit Price],format (qty_ordered,'N')[Qty to Ship],format(OpenSales,'C')[Open $]
from dbo.vwUnconfirmed_Pick_Ticket u
join dbo.vwOpenOrders_fr o
on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
where u.location_id = 200

-- 300/350
select u.location_id[Location],u.customer_id[Customer ID],bill2_name[Customer_Name],pick_ticket_no[Pick Ticket #],tracking_no[Tracking #],format(print_date,'MM/dd/yyyy')[Print Date],format(order_date,'MM/dd/yyyy')[Order Date],format(Requested_Date,'MM/dd/yyyy')[Request_Date],format(ship_date,'MM/dd/yyyy')[Ship Date],order_no[Order Date],oe_line_no[OE Line #], format(unit_price,'C')[Unit Price],format(qty_ordered,'N')[Qty to Ship],format(OpenSales,'C')[Open $]
from dbo.vwUnconfirmed_Pick_Ticket u
join dbo.vwOpenOrders_fr o
on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
where u.location_id in (300,350)

-- 400s
select u.location_id[Location],u.customer_id[Customer ID],bill2_name[Customer_Name],pick_ticket_no[Pick Ticket #],tracking_no[Tracking #],format(print_date,'MM/dd/yyyy')[Print Date],format(order_date,'MM/dd/yyyy')[Order Date],format(Requested_Date,'MM/dd/yyyy')[Request_Date],format(ship_date,'MM/dd/yyyy')[Ship Date],order_no[Order Date],oe_line_no[OE Line #], format(unit_price,'C')[Unit Price],format(qty_ordered,'N')[Qty to Ship],format(OpenSales,'C')[Open $]
from dbo.vwUnconfirmed_Pick_Ticket u
join dbo.vwOpenOrders_fr o
on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
where u.location_id like '4%'

/*
select OpenSales,*
from vwOpenOrders_fr
where OrdNum = 1321949
*/