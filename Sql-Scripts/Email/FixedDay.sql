Use P21Local;

DECLARE @tableHighLevel NVARCHAR(MAX),
		@tableOrders NVARCHAR(MAX),
		@tableCustInfo NVARCHAR(MAX),
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@salesRepName as varchar(50) = ' ', -- " = ' '" key for the function to work below
		@Subject as NVARCHAR(125),
		@countorders as int,
		@tcountorders as varchar(5),
		@sumorders as Decimal(10,2), 
		@tsumorders as varchar(10),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(100),
		@Alltables NVARCHAR(MAX);

-- test for orders
select @countorders = Count(Distinct order_no) from [dbo].[Daily_Orders_VW] 
set @tcountorders = FORMAT(@countorders, '###,###,###')

select @sumorders = SUM(extended_price) from Daily_Orders_VW 
set @tsumorders = '$' + FORMAT(@sumorders, '###,###,###.##')

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())
select @sortMonth = Month(GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

if @dayNum < 10
begin
set @dayNum = '0' + @dayNum 
end
else
begin
set @dayNum = @dayNum
end


If @sortMonth < 10
begin
set @sortDate = @yearNum + '0' + @sortMonth + @dayNum
end
else
begin
set @sortDate = @yearNum +  @sortMonth + @dayNum
end

set @fileNames = 'C:\SQL_Out\Orders_&_Quotes_Report_for_' + @sortDate + '.xlsx' 

select @Subject = @tcountorders + ' Orders for Total of  ' + @tsumorders + ' for ' + @fullDate

Select @sortDate

/*
If @countorders != 0
Begin
Set @tableHighLevel =
	N'<h2><font color="#4CC417">Summary of Orders from Today</font></h2>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Salesrep ID</th><th>SR Name</th><th>Number of Orders</th><th>Total Amount</th></tr>' +
		cast ((select "td/@align" = 'center',salesrep_id,	'',
					  "td/@align" = 'center',SalesRepName, '',
					  "td/@align" = 'center',COUNT (distinct order_no), '',
					  "td/@align" = 'center',SUM(extended_price)
			from Daily_Orders_VW
			group by salesrep_id,SalesRepName
			order by SUM(extended_price) desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

Set @tableOrders =
	N'<h3><font color="#0000FF">Orders from Today</font></h3>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Salesrep ID</th><th>Customer''s Name</th><th>Zip Code</th>' +
	N'<th>City, State</th><th>Ship to Name</th><th>Order Number</th><th>Ship Loc</th><th>Item No.</th>' +
	N'<th>Item Description</th><th>PL</th><th>QTY</th><th>EXT.AMST.$</th></tr>' +
		cast ((select "td/@align" = 'center',salesrep_id, '',
					  "td/@align" = 'center',CompanyName,		'',
					  "td/@align" = 'center',ZipCode,	    '',
					  "td/@align" = 'center',City + ', ' + SState,	'',
					  "td/@align" = 'center',ship2_CompanyName,	'',
					  "td/@align" = 'center',order_no,	'',
					  "td/@align" = 'center',ShipFromID,	'',
					  "td/@align" = 'center',customer_part_number,	'',
					  "td/@align" = 'center',item_desc,	'',
					  "td/@align" = 'center',product_group_id,	'',
					  "td/@align" = 'center',qty_ordered,	'',
					  "td/@align" = 'center',extended_price
			from Daily_Orders_VW where extended_price != 0
			order by salesrep_id,order_no,extended_price desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
End 	
Else 
Begin
SET @tableHighLevel = 'Unable to find new Orders for ' 
Set @tableOrders = @fullDate + '!'
End

    Waitfor delay '00:00:05'

set @Alltables = @tableHighLevel +
	N' ' +
	@tableOrders

 EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'gdib@ptintl.com;rlinke@ptintl.com',
      @copy_recipients = 'ddavenport@ptintl.com;mmoonan@ptintl.com;lmitchell@ptintl.com;rsneyd@ptintl.com',
      @blind_copy_recipients = 'mgoldyn@ptintl.com',
      @reply_to = 'it@ptintl.com',
      @subject = @Subject,
      @body = @Alltables,
      @importance = 'normal',
      @file_attachments = @fileNames,
      @body_Format = 'HTML';	
*/