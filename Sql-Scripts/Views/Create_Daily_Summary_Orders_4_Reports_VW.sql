/*
	01/21/2021 - create a weekly sales report that summaries the work week - reference Order Run Rate TGB.xlsx
	Bonus task comapare same week previous year
	cannot format currency, changes data type to varchar
*/

use P21Play;
/*
if OBJECT_ID ('Daily_Summary_Orders_4_Reports_VW', 'V') is not null
drop view Daily_Summary_Orders_4_Reports_VW;
go

create view [dbo].[Daily_Summary_Orders_4_Reports_VW] AS
*/
select salesrep_id,DATEPART(year,order_date)[CalYear],DATEPART(WEEK, order_date)-1[WeekNo],Datepart(day,order_date)[Day],sum(l.extended_price)[DailyTotal],format(order_date,'dd-MMM')SaleDate,datepart(dayofyear,order_date)[DayofYear]
from oe_hdr h
join customer c
on h.customer_id = c.customer_id
join oe_line l
on h.order_no = l.order_no
where approved = 'Y' and order_date between dateadd(day,datediff(day,365,GETDATE()),0)and GETDATE() and extended_price !=0
group by salesrep_id,DATEPART(year,order_date) ,DATEPART(WEEK, order_date),Datepart(day,order_date),format(order_date,'dd-MMM'),datepart(dayofyear,order_date)
--order by CalYear Desc, DayOfYear desc
go
/*
grant select on object::Daily_Summary_Orders_4_Reports_VW to p21_application_role
grant select on object::Daily_Summary_Orders_4_Reports_VW to PxxiUser
grant select on object::Daily_Summary_Orders_4_Reports_VW to [PTIDOM\P21Users]
*/
