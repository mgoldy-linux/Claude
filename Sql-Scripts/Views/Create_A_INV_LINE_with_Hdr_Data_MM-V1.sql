
with getPrev365 (customer_id_on_order,item_id,item_desc,branch_id,SalesLast12month)
as
(
select ih.customer_id,m.item_id,m.item_desc,ih.branch_id,Sum(il.extended_price)
 FROM	dbo.inv_mast m
		RIGHT OUTER JOIN  dbo.invoice_line il
		ON m.inv_mast_uid = il.inv_mast_uid 
		JOIN dbo.invoice_hdr ih
		on il.invoice_no = ih.invoice_no
Where  ih.branch_id < 401 and invoice_date between dateadd(day,datediff(day,365,GETDATE()),0) and GETDATE()  and il.item_desc not like '%rebate%' and customer_id = 42641  -- and ih.customer_id < 10030
Group By ih.customer_id,m.item_id,m.item_desc,branch_id
),
 getPrev730 (customer_id_on_order,item_id,item_desc,branch_id,SalesPrevious12months)
as
(
select ih.customer_id,m.item_id,m.item_desc,ih.branch_id,Sum(il.extended_price)
 FROM	dbo.inv_mast m
		RIGHT OUTER JOIN  dbo.invoice_line il
		ON m.inv_mast_uid = il.inv_mast_uid 
		JOIN dbo.invoice_hdr ih
		on il.invoice_no = ih.invoice_no 
Where  ih.branch_id < 401 and invoice_date between dateadd(day,datediff(day,730,GETDATE()),0) and dateadd(day,datediff(day,365,GETDATE()),0)  and il.item_desc not like '%rebate%' and branch_id = 100 -- and ih.customer_id < 10030
Group By ih.customer_id,m.item_id,m.item_desc,branch_id
),
getBoth (customer_id_on_order,item_id,item_desc,branch_id,SalesLast12month,SalesPrevious12months)
as
(
	select
	case
	when p3.customer_id_on_order is null then p7.customer_id_on_order
	else p3.customer_id_on_order
	End, 
	case 
	when p3.item_id is null and p7.item_id is null then 'Missing' 
	when p3.item_id is null and p7.item_id is not null then p7.item_id
	when p3.item_id is not null and p7.item_id is null then p3.item_id else p3.item_id end, 
	case 
	when p3.item_desc is null and p7.item_desc is null then 'Missing' 
	when p3.item_desc is null and p7.item_desc is not null then p7.item_desc
	when p3.item_desc is not null and p7.item_desc is null then p3.item_desc else p3.item_desc end,
	case when p3.branch_id is null then p7.branch_id else p3.branch_id end,
	SalesLast12month,SalesPrevious12months
	from getPrev365 p3
	full outer join getPrev730 p7
	on p3.customer_id_on_order = p7.customer_id_on_order and  p3.item_id = p7.item_id
)
select customer_name,gb.*
from getBoth gb
join customer c
on gb.customer_id_on_order = c.customer_id
order by item_id

/*
FULL OUTER JOIN dbo.customer c
FULL OUTER JOIN dbo.invoice_hdr ih
LEFT OUTER JOIN dbo.contacts  co
ON ih.salesrep_id = co.id 
ON c.customer_id = gb.customer_id_on_order
join dbo.address a
on c.customer_id = a.id
left join Customer_SR_Territories tsr
on c.customer_id = tsr.customer_id_on_order 
order by customer_id_on_order
*/