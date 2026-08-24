/*
	09/17/2020 - create a summary orders view for email
	09/17/2020 - tested in play

*/
use P21Play;

/*
if OBJECT_ID ('Daily_Summary_Orders_VW', 'V') is not null
drop view Daily_Summary_Orders_VW;
go

create view [dbo].[Daily_Summary_Orders_VW] AS
*/
with getApprove(SalesManager,salesrep_id,ApproveOrders,ApproveTotals)
as
(
	select  SalesManager,salesrep_id,Count(Distinct order_no),Sum(extended_price)
	from Daily_Orders_VW
	where approved = 'Y' and extended_price != 0
	group by SalesManager,salesrep_id
),
getUnapprove(SalesManager,salesrep_id,UnapproveOrders,UnapproveTotals)
as
(
	select SalesManager,salesrep_id,Count(Distinct order_no),Sum(extended_price)
	from Daily_Orders_VW
	where approved = 'N' and extended_price != 0
	group by SalesManager,salesrep_id
)
select ga.SalesManager,ga.salesrep_id,ga.ApproveOrders,ga.ApproveTotals,coalesce(gu.UnapproveOrders,0)[OrdersUnapproved],coalesce(gu.UnapproveTotals,'0.00')[TotalUnapprove]
from getApprove ga
left join getUnapprove gu
on ga.salesrep_id = gu.salesrep_id;

go
/*
grant select on object::Daily_Summary_Orders_VW to p21_application_role
grant select on object::Daily_Summary_Orders_VW to PxxiUser
grant select on object::Daily_Summary_Orders_VW to [PTIDOM\P21Users]
*/