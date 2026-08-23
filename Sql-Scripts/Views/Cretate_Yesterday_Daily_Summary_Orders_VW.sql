/*
	09/17/2020 - create a summary orders view for email
	09/17/2020 - tested in play
	10/02/2020 - for failed email
*/
use P21;
/*
if OBJECT_ID ('Daily_Yesterday_Summary_Orders_VW', 'V') is not null
drop view Daily_Yesterday_Summary_Orders_VW;
go

create view [dbo].[Daily_Yesterday_Summary_Orders_VW] AS
*/
with getApprove(salesrep_id,ApproveOrders,ApproveTotals)
as
(
	select  salesrep_id,Count(Distinct order_no),Sum(extended_price)
	from Daily_Yesterday_Orders_VW
	where approved = 'Y' and extended_price != 0
	group by salesrep_id
),
getUnapprove(salesrep_id,UnapproveOrders,UnapproveTotals)
as
(
	select salesrep_id,Count(Distinct order_no),Sum(extended_price)
	from Daily_Yesterday_Orders_VW
	where approved = 'N' and extended_price != 0
	group by salesrep_id
)
select ga.salesrep_id,ga.ApproveOrders,ga.ApproveTotals,coalesce(gu.UnapproveOrders,0)[OrdersUnapproved],coalesce(gu.UnapproveTotals,'0.00')[TotalUnapprove]
from getApprove ga
left join getUnapprove gu
on ga.salesrep_id = gu.salesrep_id