use  WQMetaData;

/*
select OpenSales,Days,DaysLate,*
from dbo.vwOpenOrders_fr v
where DaysLate > 0 and OpenSales > 0
order by v.Days
*/

with getFirstSet (Location, [1-7 Days # of Pick Tickets],[Open $1])
as
(
	select u.location_id,count(pick_ticket_no),sum(OpenSales)
	from dbo.vwUnconfirmed_Pick_Ticket u
	join dbo.vwOpenOrders_fr o
	on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
	where DATEDIFF(dd, u.required_date, GETDATE()) between 1 and 7
	group by u.location_id
	),
getSecondSet (Location, [8 - 30 Days # of Pick Tickets],[Open $2])
as
(
	select u.location_id,count(pick_ticket_no),sum(OpenSales)
	from dbo.vwUnconfirmed_Pick_Ticket u
	join dbo.vwOpenOrders_fr o
	on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
	where DATEDIFF(dd, u.required_date, GETDATE()) between 8 and 30
	group by u.location_id
	),
getThirdSet (Location, [31 - 60 Days # of Pick Tickets],[Open $3])
as
(
	select u.location_id,count(pick_ticket_no),sum(OpenSales)
	from dbo.vwUnconfirmed_Pick_Ticket u
	join dbo.vwOpenOrders_fr o
	on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
	where DATEDIFF(dd, u.required_date, GETDATE()) between 31 and 60
	group by u.location_id
	),
getfourthSet (Location, [61 + Days # of Pick Tickets],[Open $4])
as
(
	select u.location_id,count(pick_ticket_no),sum(OpenSales)
	from dbo.vwUnconfirmed_Pick_Ticket u
	join dbo.vwOpenOrders_fr o
	on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
	where DATEDIFF(dd, u.required_date, GETDATE()) > 61
	group by u.location_id
	)
select f.Location,f.[1-7 Days # of Pick Tickets],f.[Open $1],s.[8 - 30 Days # of Pick Tickets],s.[Open $2],t.[31 - 60 Days # of Pick Tickets],t.[Open $3],fo.[61 + Days # of Pick Tickets],fo.[Open $4]
from getFirstSet f
left join getSecondSet s
on f.Location = s.Location
left join getThirdSet t
on f.Location = t.Location
left join getfourthSet fo
on f.Location = fo.Location
order by f.Location

/*
select u.location_id,pick_ticket_no,OpenSales,Requested_Date,required_date,release_no
from dbo.vwUnconfirmed_Pick_Ticket u
join dbo.vwOpenOrders_fr o
on u.order_no  = o.OrdNum and u.oe_line_no = o.OrdLineNum
where Days between 1 and 7 and u.location_id = 200
order by location_id
*/