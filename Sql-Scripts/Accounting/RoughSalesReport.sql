/*
	start date: 20200106
	rough ideas for email sales report
	WHEN o.source_code_no = 706 THEN 'Order Entry'
	WHEN o.source_code_no = 708 THEN 'EDI'
	WHEN o.source_code_no = 709 THEN 'Quote'
*/

use p21;

-- Get orders 
select (c.first_name + ' ' + c.last_name)[Name],customer_name,customer_part_number,qty_shipped,order_date,order_no,sales_price 
from p21_sales_history_report_view s
join contacts c
on s.salesrep_id = c.id
where order_date > '01/01/2020'
order by order_date desc

-- get invoices
select (c.first_name + ' ' + c.last_name)[Name],invoice_no, bill2_name, total_amount
from invoice_hdr i
join contacts c
on i.salesrep_id = c.id
where YEAR(invoice_date) = 2020 and MONTH(invoice_date) = 1 and DAY(invoice_date) = 3
order by Name,invoice_no

--get quotes
Declare @dayDate as varchar(3),
		@monthName as varchar(20),
		@dayYear as varchar(5),
		--@fullDate as varchar(35);
		@yestDate as varchar(35);
/* Today
select @dayDate = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @dayYear = DATENAME(YEAR,GetDate())

Select @fullDate = @monthName + ' ' + @dayDate + ', ' + @dayYear
*/

-- Yesterday
select @dayDate = DATENAME(DAY,datediff(day,1,GETDATE()))
select @monthName = DATENAME(MONTH,datediff(day,1,GETDATE()))
select @dayYear = DATENAME(YEAR,datediff(day,1,GETDATE()))

Select @yestDate = @monthName + ' ' + @dayDate + ', ' + @dayYear
select @dayDate

select order_no, order_date, customer_name, taker, o.created_by, o.source_code_no
from oe_line o
join customer c
on o.customer_id = c.customer_id
where Year(order_date) =  '2020' and o.source_code_no = 709
order by order_no desc


select *, 
from oe_hdr
where order_no = 1016124

