/*
	05/22/2020 - test email Open quote  Monday Morning at 6:17 AM
	 @recipients = gdib@ptintl.com
	 File names: AllOpenQuotes_YYYYMMDD.xlxs; SummaryOpenQuotes_YYYYMMDD.xlxs
	 Assuming there will always be at least one quote
*/
declare @dayNum as varchar(3),
		@monthName as varchar(20),
		@monthName2 as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(255),
		@bodyText as varchar(MAX),
		@QuoteTable as varchar(MAX),
		@OrderTable as varchar(MAX),
		@Subject as NVARCHAR(125);
 
select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())
select @sortMonth = Month(GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

If @sortMonth < 10 
begin
set @sortMonth =  '0' + @sortMonth
end
else 
begin
set @sortMonth = @sortMonth
end

If @dayNum < 10 
begin
set @dayNum =  '0' + @dayNum
end
else 
begin
set @dayNum = @dayNum
end

set @sortDate = @yearNum + @sortMonth + @dayNum

set @fileNames = 'C:\SQL_Out\All_Open_Orders_Quotes_' + @sortDate + '.xlsx'  
set @OrderTable = 
	N'<h1><font color="#0000FF">Open Orders Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Orders</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenOrders,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Orders_Summary 
			order by TotalValue 
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

set @QuoteTable = 
	N'<h1><font color="#FF82FF">Open Quotes Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Quotes</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenQuotes,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Quote_Summary 
			order by TotalValue 
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

set @Subject = 'All Open Orders Quotes from ' + @fullDate  + '.'
set @bodyText = @OrderTable + @QuoteTable

EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'gdib@ptintl.com',
      @blind_copy_recipients = 'mgoldyn@ptintl.com',
      @reply_to = 'it@ptintl.com',
      @from_address = 'it@ptintl.com',
      @subject = @Subject,
      @body = @bodyText,
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'HTML';