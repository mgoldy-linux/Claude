declare @Qcount1017 as int,
		@Qcount1026 as int,
		@Opcount1017 as int,
		@Opcount1026 as int,
		@dayNum as varchar(3),
		@dayNum2 as varchar(3),
		@monthName as varchar(20),
		@monthName2 as varchar(20),
		@yearNum as varchar(5),
		@yearNum2 as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(511),
		@noQuoteFound as varchar(50),
		@bodyText as varchar(MAX),
		@QuoteTable as varchar(MAX),
		@OrderTable as varchar(MAX),
		@SubName as varchar(50),
		@Subject as NVARCHAR(125);
 
 -- set subject Name 
 set @SubName = 'TGB 1017'
 
 -- test for open qoutes for 1017
 select @Qcount1017 = COUNT(*) from d_Open_Quote_Summary where SalesRepName like '%1017%'
 select @Opcount1017 = COUNT(*) from d_Open_Orders_Summary where SalesRepName like '%1017%'

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

set @OrderTable = 
	N'<h1><font color="#0000FF">Open Orders Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Orders</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'left',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenOrders,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Orders_Summary where SalesRepName like '%1017%'
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

set @QuoteTable = 
	N'<h1><font color="#EE82EE">Open Quotes Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Quotes</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'left',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenQuotes,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Quote_Summary where SalesRepName like '%1017%' 
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'


set @fileNames = 'C:\SQL_Out\TGB-New_1017_Open_Orders_Quotes_' + @sortDate + '.xlsx' 

set @Subject = @SubName + ' Open Orders & Quotes Report for ' + @fullDate  + '.'
set @bodyText = @OrderTable + @QuoteTable -- + @noQuoteFound until fix logic on orders and quotes found

EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'sales@tgbindustrial.com',
      @copy_recipients = 'george.dib@solveindustrial.com;scott.kuhn@solveindustrial.com;mike.maggio@solveindustrial.com;josh.loftus@solveindustrial.com;Beau.Wiley@solveindustrial.com',
      @blind_copy_recipients = 'mark.goldyn@solveindustrial.com',
      @reply_to = 'reports@solveindustrial.com',
      @from_address = 'reports@solveindustrial.com',
      @subject = @Subject,
      @body = @bodyText,
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'HTML';
