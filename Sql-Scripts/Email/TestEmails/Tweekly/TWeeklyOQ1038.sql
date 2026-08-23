/*
	05/20/2020 - test email Open quote  Monday Morning at 6 AM
	 @recipients = mmattis@icsreps.com;jmackenroth@icsreps.com, CC = rlinke@ptintl.com 
	 Industrial-Components_1033_Open_Quotes_20200520.xlsx,Industrial-Components_1038_Open_Quotes_20200520.xlsx,Industrial-Components_1039_Open_Quotes_20200520.xlsx,Industrial-Components_1040_Open_Quotes_20200520.xlsx
	 08/21/2020 - add orders to spreadsheet, change file name: NTS_1033_Open_Orders_Quotes_YYYYMMDD.xlxs,
*/
declare @dayNum as varchar(3),
		@dayNum2 as varchar(3),
		@monthName as varchar(20),
		@monthName2 as varchar(20),
		@yearNum as varchar(5),
		@yearNum2 as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@2weeksAgo as varchar(12),
		@sortMonth as varchar(2),
		@fileNames as varchar(512),
		@bodyText as varchar(MAX),
		@noQuoteFound as varchar(50),
		@QuoteTable as varchar(MAX),
		@OrderTable as varchar(MAX),
		@SubName as varchar(50),
		@Subject as NVARCHAR(125);

 -- set subject Name 
 set @SubName = 'Industrial-Components'

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())
select @sortMonth = Month(GetDate())

Set @2weeksAgo = dateadd(day,datediff(day,14,GETDATE()),0)
set @monthName2 = DATENAME(Month,@2weeksago)
set @dayNum2 = DATENAME(Day,@2weeksago)
set @yearNum2 = DATENAME(Year,@2weeksago)

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

set @fileNames = 'C:\SQL_Out\Industrial-Components_1033_Open_Orders_Quotes_' + @sortDate + '.xlsx'  + ';' + 'C:\SQL_Out\Industrial-Components_1038_Open_Orders_Quotes_' + @sortDate + '.xlsx' + ';' + 'C:\SQL_Out\Industrial-Components_1039_Open_Orders_Quotes_' + @sortDate + '.xlsx' + ';' + 'C:\SQL_Out\Industrial-Components_1040_Open_Orders_Quotes_' + @sortDate + '.xlsx'

set @OrderTable = 
	N'<h1><font color="#0000FF">Open Orders Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Orders</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenOrders,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Orders_Summary where SalesRepName like '%33%' or  SalesRepName like '%38%' or  SalesRepName like '%39%' or  SalesRepName like '%40%'
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
set @Subject = @SubName + ' Open Quotes from ' + @monthName2 + ' ' + @dayNum2 + ', ' + @yearNum2  + ' to today.'


set @QuoteTable = 
	N'<h1><font color="#EE82EE">Open Quotes Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Quotes</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenQuotes,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Quote_Summary where SalesRepName like '%33%' or  SalesRepName like '%38%' or  SalesRepName like '%39%' or  SalesRepName like '%40%'
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
set @Subject = @SubName + ' Open Orders & Quotes Report for ' + @monthName2 + ' ' + @dayNum2 + ', ' + @yearNum2  + '.'


set @bodyText = @OrderTable + @QuoteTable

EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'mmattis@icsreps.com;jmackenroth@icsreps.com',
	  @copy_recipients = 'rlinke@ptintl.com',
      @blind_copy_recipients = 'mgoldyn@ptintl.com',
      @reply_to = 'it@ptintl.com',
      @from_address = 'it@ptintl.com',
      @subject = @Subject,
      @body = @bodyText,
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'HTML';