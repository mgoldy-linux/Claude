/*
	01/21/2021 - create a weekly sales report that summaries the work week - reference Order Run Rate TGB.xlsx
	Bonus task comapare same week previous year
*/

select salesrep_id,DATEPART(year,order_date)[CalYear],DATEPART(WEEK, order_date)-1[Week#],Datepart(day,order_date)[Day],sum(l.extended_price)[daily total] --,(DATEPART(WEEK, order_date)-1)[Wk#],DATEPART(year,order_date)[year],
from oe_hdr h
join customer c
on h.customer_id = c.customer_id
join oe_line l
on h.order_no = l.order_no
where salesrep_id in(1017,1020,1026) and approved = 'Y' /*and DATEPART(WEEK, order_date)-1 = 1*/ and order_date between dateadd(day,datediff(day,365,GETDATE()),0)and GETDATE() and extended_price !=0
group by salesrep_id,DATEPART(year,order_date) ,DATEPART(WEEK, order_date),Datepart(day,order_date)
order by CalYear Desc, [Week#] desc


--select DATEPART(week, '2020-12-30')