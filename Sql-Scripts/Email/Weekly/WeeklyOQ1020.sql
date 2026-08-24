/*
	05/21/2020 - test email Open quote  Monday Morning at 6:17 AM
	 @recipients = sales@DJ-Reps.com, CC = rlinke@ptintl.com 
	 File names: DJ-Reps_1020_Open_Quotes_YYYYMMDD.xlxs
	 08/21/2020 - add orders to spreadsheet, change file name: Name_sr_id_Open_Orders_Quotes_YYYYMMDD.xlxs, delete two weeks date
*/
declare @Qcount1020 as int,
		@Opcount1020 as int,
		@dayNum as varchar(3),
		@dayNum2 as varchar(3),
		@monthName as varchar(20),
		@monthName2 as varchar(20),
		@yearNum as varchar(5),
		@yearNum2 as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@2weeksAgo as varchar(12),
		@sortMonth as varchar(2),
		@fileNames as varchar(255),
		@noQuoteFound as varchar(50),
		@bodyText as varchar(MAX),
		@QuoteTable as varchar(MAX),
		@OrderTable as varchar(MAX),
		@SubName as varchar(50),
		@Subject as NVARCHAR(125);
 
 -- set subject Name 
 set @SubName = 'DJ-Reps'
 
 -- test for open qoutes for 1020
select @Qcount1020 = COUNT(*) from d_Open_Quote_Summary where SalesRepName like '%20%'
select @Opcount1020 = COUNT(*) from d_Open_Orders_Summary where SalesRepName like '%20%'

--set no quotes found
set @noQuoteFound = ' '

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
	N'<h1><font color="#0000FF">Open Order Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Orders</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenOrders,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Orders_Summary where SalesRepName like '%20%' 
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'
			
set @QuoteTable = 
	N'<h1><font color="#EE82EE">Open Quotes Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Quotes</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenQuotes,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Quote_Summary where SalesRepName like '%20%' 
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

if @Qcount1020 >= 1 and @Opcount1020 >= 1
Begin
	set @fileNames = 'C:\SQL_Out\DJ-Reps_1020_Open_Orders_Quotes_' + @sortDate + '.xlsx' 
End
else if  @Qcount1020 >= 1 and @Opcount1020 = 0
Begin 
	set @fileNames = 'C:\SQL_Out\DJ-Reps_1020_Open_Orders_Quotes_' + @sortDate + '.xlsx' 
	set @OrderTable =  ''
End
else if  @Qcount1020 = 0 and @Opcount1020 >= 1
Begin 
	set @fileNames = 'C:\SQL_Out\DJ-Reps_1020_Open_Orders_Quotes_' + @sortDate + '.xlsx' 
	set @QuoteTable =  ''
End
else
Begin 
	set @fileNames = ''	
	set @QuoteTable = '' 
	set @OrderTable =  ''
	set @noQuoteFound = 'No Open Orders or Quotes Found.'
End


set @Subject = @SubName + ' Open Orders & Quotes Report ' + @fullDate  + '.'
set @bodyText = @OrderTable + @QuoteTable + @noQuoteFound


EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'sales@DJ-Reps.com',
      @copy_recipients = 'rlinke@ptintl.com',
      @blind_copy_recipients = 'mgoldyn@ptintl.com',
      @reply_to = 'it@ptintl.com',
      @from_address = 'it@ptintl.com',
      @subject = @Subject,
      @body = @bodyText,
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'HTML';