/*
	01/24/2020 - Version 1
	01/27/2020 - version 2 fixed no sales person and if no Quotes 
	02/03/2020 - remove george, $0 lines - per email, change alignment to center
	02/06/2020 - add Customer Contact, Customer Phone #, Inside Sales, remove Zipcode
	11/30/2020 - replace @solveindustrial.com with @solveindustrial.com
	06/11/2021 - add email address to table
	08/11/2022 - add mmaggio@bearingslimited.com
*/
Use P21;

DECLARE @tableHighLevel NVARCHAR(MAX),
		@tableQuotes NVARCHAR(MAX),
		@tableCustInfo NVARCHAR(MAX),
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@salesRepName as varchar(50) = ' ', -- " = ' '" key for the function to work below
		@Subject as NVARCHAR(125),
		@countQuotes as int,
		@sumQuotes as Decimal(10,2), -- individual Quotes
		@sumSRQuotes as Decimal(10,2), -- Each SR Quotes
		@Alltables NVARCHAR(MAX);

-- test for Quotes
select @countQuotes = Count(Distinct order_no) from [dbo].[Daily_Quotes_VW] where salesrep_id = 1028

select @sumSRQuotes = SUM(extended_price) from Daily_Quotes_VW where  salesrep_id = 1028

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

Select @salesRepName += x.sr 
From
(
	Select Distinct (SalesRepName) as sr
	from [dbo].[Daily_Quotes_VW] where salesrep_id = 1028
	)
as x;

if @salesRepName = ''
begin
set @salesRepName = ' RGW Sales (1028) '
end
else 
begin
set @salesRepName = @salesRepName
end 

Select @Subject = 'Daily Quotes Summary for' + @salesRepName + ' for ' + @fullDate

If @countQuotes != 0
Begin
Set @tableHighLevel =
	N'<h2><font color="#4cc417">Summary of your Quotes from Today</font></h2>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Number of Quotes</th><th>Total Amount</th></tr>' +
		cast ((select "td/@align" = 'center',@countQuotes,	'',
					  "td/@align" = 'center',@sumSRQuotes
			
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

Set @tableQuotes =
	N'<h3><font color="#0000FF">Quotes from Today</font></h3>' +
	N'<table border="1">' +
	N'<tr align="left"><th>City, State</th><th>Customer Contact</th><th>email</th><th>Cust, Phone #</th>' +
	N'<th>Customer''s Name</th><th>Order Number</th><th>Inside Sales</th><th>Branch</th><th>Item No.</th>' +
	N'<th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
		cast ((select "td/@align" = 'center',City + ', ' + SState,	'',
					  "td/@align" = 'center',CustName,		'',
					  "td/@align" = 'center',email,		'',
					  "td/@align" = 'center',TelNo,		'',
					  "td/@align" = 'center',CompanyName,		'',
					  "td/@align" = 'center',order_no,	'',
					  "td/@align" = 'center',taker,	'',
					  "td/@align" = 'center',BranchID, '',
					  "td/@align" = 'center',customer_part_number,	'',
					  "td/@align" = 'center',item_desc,	'',
					  "td/@align" = 'center',product_group_id,	'',
					  "td/@align" = 'center',qty_ordered,	'',
					  "td/@align" = 'center',extended_price
			from Daily_Quotes_VW where salesrep_id = 1028 and extended_price != 0
			order by ZipCode
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
SET @tableHighLevel = 'Unable to find new Quotes for ' 
Set @tableQuotes =@fullDate + '!'
End

    Waitfor delay '00:00:05'

set @Alltables = @tableHighLevel +
	N' ' +
	@tableQuotes

 EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'robert@rgwsalescanada.com',
      @copy_recipients = 'gdib@solveindustrial.com;mmaggio@bearingslimited.com',
      @blind_copy_recipients = 'mgoldyn@solveindustrial.com',
      @reply_to = 'it@solveindustrial.com',
      @subject = @Subject,
      @body = @Alltables,
      @importance = 'Normal',
      @body_Format = 'HTML';	
