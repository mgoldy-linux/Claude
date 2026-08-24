/*
	 02/24/2020 - Create a monthly sales report for each rep
	 02/24/2020 - emailed the 1st of the month, for previous month, dates are for fiscal year 7/1 to 6/30
	 02/24/2020 - the report should have cust#, customer name, product line abbr, product line desc, month sales, year sales, last year sales for the same month, last sales to same month
	 need get customer by default id
	 02/27/2020  - use period instead of dates
	 02/27/2020 - trying individual files
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
order by YearPeriod
