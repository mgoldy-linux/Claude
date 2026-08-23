/*
	 02/24/2020 - Create a monthly sales report for each rep
	 02/24/2020 - emailed the 1st of the month, for previous month, dates are for fiscal year 7/1 to 6/30
	 02/24/2020 - the report should have cust#, customer name, product line abbr, product line desc, month sales, year sales, last year sales for the same month, last sales to same month
	 need get customer by default id
	 02/27/2020  - use period instead of dates
	 02/27/2020 - just the previous month
 */
use P21Play;
/*
go

if OBJECT_ID ('dPreviousMonth_Sales', 'V') is not null
drop view dPreviousMonth_Sales;
go
create view [dbo].[dPreviousMonth_Sales] AS
*/
Declare @Period as int,
		@currentYear as int,
		@fiscalYear as int,
		@currentMonth as int;

Set @currentMonth =  Month(GetDate())
Set @currentYear = Year(GetDate())

if @currentMonth < 8
begin
	set @fiscalYear = @currentYear
end
else
begin
	set @fiscalYear = @currentYear + 1
end

Select
	@Period = case @currentMonth
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
),
getInvoices(invoice_no,customer_id,inv_mast_uid,item_id,extended_price,product_group_id,p,CFYr)
as
(
	select h.invoice_no,customer_id,l.inv_mast_uid,l.item_id,l.extended_price,l.product_group_id,@Period,@fiscalYear
	from invoice_hdr h
	join invoice_line l
	on h.invoice_no = l.invoice_no
	where h.period = @Period and year_for_period = @fiscalYear
),
joinCustInvc(customer_id,customer_name,product_group_id,total_sales,cs,p,CFYr)
As
(
	select gcn.customer_id,customer_name,product_group_id,SUM(extended_price),cs,p,CFYr
	from getCustNames gcn
	left join getInvoices gi
	on gcn.customer_id = gi.customer_id
	where product_group_id is not null
	group by gcn.customer_id,customer_name,product_group_id,cs,p,CFYr
)
select customer_id,customer_name,jci.product_group_id,pg.product_group_desc,total_sales,cs,p,CFYr
from joinCustInvc jci
join product_group pg
on jci.product_group_id = pg.product_group_id
order by customer_id