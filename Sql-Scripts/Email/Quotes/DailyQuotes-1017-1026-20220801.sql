/*
	01/24/2020 - Version 1
	01/27/2020 - version 2 fixed no sales person and if no Quotes 
	01/31/2020 - change email to sales@tgbindustrial.com
	02/03/2020 - remove george, $0 lines - per email, change alignment to center
	02/06/2020 - fixed @copy_recipients 
	02/06/2020 - add Customer Contact, Customer Phone #, Inside Sales, remove Zipcode
	09/04/2020 - add 1017, set sr to ' TGB Industrial Sales (1017,1026) '
	09/10/2020 - change subject back to old format
	11/30/2020 - replace @solveindustrial.com with @solveindustrial.com, not for it@ptintl.com
	06/11/2021 add email address to table
	08/01/2022 - add Scott Kuhn <skuhn@bearingslimited.com> ,change importance & reply email
	08/11/2022 - add mmaggio@bearingslimited.com  loftus@bearingslimited.com
*/

Use P21;

DECLARE @tableHighLevel1026 NVARCHAR(MAX),
		@tableQuotes1026 NVARCHAR(MAX),
		@tableHighLevel1017 NVARCHAR(MAX),
		@tableQuotes1017 NVARCHAR(MAX),
		@tableCustInfo NVARCHAR(MAX),
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@salesRepName as varchar(50) = ' ', -- " = ' '" key for the function to work below
		@Subject as NVARCHAR(125),
		@countQuotes1017 as int,
		@sumQuotes1017 as Decimal(10,2), -- individual Quotes
		@sumSRQuotes1017 as Decimal(10,2), -- Each SR Quotes
		@countQuotes1026 as int,
		@sumQuotes1026 as Decimal(10,2), -- individual Quotes
		@sumSRQuotes1026 as Decimal(10,2), -- Each SR Quotes
		@Alltables NVARCHAR(MAX);

-- test for Quotes
select @countQuotes1017 = Count(Distinct order_no) from [dbo].[Daily_Quotes_VW] where salesrep_id = 1017
select @countQuotes1026 = Count(Distinct order_no) from [dbo].[Daily_Quotes_VW] where salesrep_id = 1026

select @sumSRQuotes1017 = SUM(extended_price) from Daily_Quotes_VW where  salesrep_id = 1017
select @sumSRQuotes1026 = SUM(extended_price) from Daily_Quotes_VW where  salesrep_id = 1026

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

Select @salesRepName += x.sr 
From
(
	Select Distinct (SalesRepName) as sr
	from [dbo].[Daily_Orders_VW] where salesrep_id = 1026 or salesrep_id = 1027 and extended_price != 0
	)
as x;

if @salesRepName = ''
begin
set @salesRepName = ' TGB Industrial Sales (1017,1026) '
end
else 
begin
set @salesRepName = ' TGB Industrial Sales (1017,1026) '
end 

select @Subject =  'Daily Quotes Summary for' + @salesRepName + ' for ' + @fullDate

-- create 1017 tables
If @countQuotes1017 != 0
Begin
Set @tableHighLevel1017 =
	N'<h3><font color="#4CC417">Summary 1017 Quotes last 24 hours</font></h3>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Number of Quotes</th><th>Total Amount</th></tr>' +
		cast ((select "td/@align" = 'center',@countQuotes1017,	'',
					  "td/@align" = 'center',@sumSRQuotes1017
			
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

Set @tableQuotes1017 =
	N'<h4><font color="#0000FF">1017 Quotes last 24 hours</font></h4>' +
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
			from Daily_Quotes_VW where salesrep_id = 1017 and extended_price != 0
			order by ZipCode
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
SET @tableHighLevel1017 = 'Unable to find new Quotes for 1017 in the last 24 hours.'
Set @tableQuotes1017 = ''
End
-- create 1026 tables
If @countQuotes1026 != 0
Begin
Set @tableHighLevel1026 =
	N'<h3><font color="#4CC417">Summary 1026 Quotes last 24 hours</font></h3>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Number of Quotes</th><th>Total Amount</th></tr>' +
		cast ((select "td/@align" = 'center',@countQuotes1026,	'',
					  "td/@align" = 'center',@sumSRQuotes1026
			
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

Set @tableQuotes1026 =
	N'<h4><font color="#0000FF">1026 Quotes last 24 hours</font></h4>' +
	N'<table border="1">' +
	N'<tr align="left"><th>City, State</th><th>Customer Contact</th><th>Cust, Phone #</th>' +
	N'<th>Customer''s Name</th><th>Order Number</th><th>Inside Sales</th><th>Branch</th><th>Item No.</th>' +
	N'<th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
		cast ((select "td/@align" = 'center',City + ', ' + SState,	'',
					  "td/@align" = 'center',CustName,		'',
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
			from Daily_Quotes_VW where salesrep_id = 1026 and extended_price != 0
			order by ZipCode
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
SET @tableHighLevel1026 = 'Unable to find new Quotes for 1026 in the last 24 hours.' 
Set @tableQuotes1026 = ''
End

    Waitfor delay '00:00:05'

set @Alltables =  @tableHighLevel1017 +
	N' ' +
	@tableHighLevel1026 +
	N' ' +
	@tableQuotes1017 +
	N' ' +
	@tableQuotes1026

 EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'sales@tgbindustrial.com',
      @copy_recipients = 'gdib@solveindustrial.com;skuhn@bearingslimited.com;loftus@bearingslimited.com;mmaggio@bearingslimited.com',
      @blind_copy_recipients = 'mgoldyn@solveindustrial.com',
      @reply_to = 'it@solveindustrial.com',
      @subject = @Subject,
      @body = @Alltables,
      @importance = 'normal',
      @body_Format = 'HTML';	
