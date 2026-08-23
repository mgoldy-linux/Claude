/*
	 02/24/2020 - Create a monthly sales report for each rep
	 02/24/2020 - emailed the 1st of the month, for previous month, dates are for fiscal year 7/1 to 6/30
	 02/24/2020 - the report should have cust#, customer name, product line abbr, product line desc, month sales, year sales, last year sales for the same month, last sales to same month
	 need get customer by default id
	 
*/
use P21Play;
/*
go

if OBJECT_ID ('dMonthly_Sales', 'V') is not null
drop view dMonthly_Sales;
go
create view [dbo].[dMonthly_Sales] AS
*/
Declare @startPeriod as int, 
		@endPeriod as int,
		@currentYear as int,
		@fiscalYear as int,
		@prevFiscalYear as int,
		@currentMonth as int,
		@testDate as date;

Set @currentMonth =  Month(GetDate())
Set @currentYear = Year(GetDate())
Set @startPeriod = 1

if @currentMonth < 7
begin
	set @fiscalYear = @currentYear
	set @prevFiscalYear = @currentYear - 1
end
else
begin
	set @fiscalYear = @currentYear + 1
	set @prevFiscalYear = @currentYear
end

Select
	@endPeriod = case @currentMonth
	When 1 then  6
	When 2 then  7
	When 3 then  8
	When 4 then  9
	When 5 then  10
	When 6 then  11
	When 7 then  12
	When 8 then  1
	When 9 then  2
	When 10 then 3
	When 11 then 4
	When 12 then 5
end;

with getCustNames(customer_id,customer_name,cs)
as
(
	select customer_id,customer_name,(salesrep_id + '_' + customer_id_string)
	from customer c
	--where salesrep_id = 1032
),
getInvoices(invoice_no,customer_id,inv_mast_uid,item_id,extended_price,product_group_id,PTIperiod,YearPeriod)
as
(
	select h.invoice_no,customer_id,l.inv_mast_uid,l.item_id,l.extended_price,l.product_group_id,h.period,h.year_for_period
	from invoice_hdr h
	join invoice_line l
	on h.invoice_no = l.invoice_no
	Where h.period between @startPeriod and @endPeriod and (year_for_period = @currentYear or year_for_period = @prevFiscalYear)
	
),
joinCustInvc(customer_id,customer_name,product_group_id,total_sales,cs,PTIperiod,YearPeriod)
As
(
	select gcn.customer_id,customer_name,product_group_id,SUM(extended_price),cs,PTIperiod,YearPeriod
	from getCustNames gcn
	left join getInvoices gi
	on gcn.customer_id = gi.customer_id
	where product_group_id is not null
	group by gcn.customer_id,customer_name,product_group_id,cs,PTIperiod,YearPeriod
)
select customer_id,customer_name,jci.product_group_id,pg.product_group_desc,total_sales,cs,PTIperiod,YearPeriod
from joinCustInvc jci
join product_group pg
on jci.product_group_id = pg.product_group_id
order by customer_id
/*
with getOrdersNo(order_no,customer_id)
as
(
	select order_no, customer_id
	from oe_hdr h
	join oe_hdr_salesrep s
	on h.order_no = s.order_number
	where Year(order_date) = 2020 and MONTH(order_date) = 01 
),
getCustName(customer_id,customer_name,order_no)
as
(
	select gon.customer_id,customer_name,order_no
	from getOrdersNo gon
	join customer c
	on gon.customer_id = c.customer_id
),
getPartNums(customer_id,customer_name,inv_mast_uid,product_group_id,extended_price)
as
(
	select customer_id,customer_name,l.inv_mast_uid,l.product_group_id,l.extended_price
	from getCustName gcn
	join oe_line l
	on gcn.order_no = l.order_no
)
select customer_id,customer_name,gpn.product_group_id,pg.product_group_desc,sum(extended_price)[Month Sales]
from getPartNums gpn
join product_group pg
on gpn.product_group_id = pg.product_group_id
group by customer_id,customer_name,gpn.product_group_id,pg.product_group_desc
order by customer_id


where gpn.inv_mast_uid = 22686




select *
from inv_mast
where item_id = 'SPA180X4-2517'



select h.invoice_no,l.extended_price,h.order_no
from invoice_hdr h
join invoice_line l
on h.invoice_no = l.invoice_no
where customer_id = 13766 and YEAR(invoice_date) = 2020 and MONTH(invoice_date) = 2
*/