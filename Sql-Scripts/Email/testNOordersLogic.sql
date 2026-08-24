/*
	05/21/2020 - test email Open quote  Monday Morning at 6 AM
	 @recipients = ramsler@eracos.com, CC = gdib@ptintl.com 
	 File names: TPW-Inc_18353_Open_Quotes_YYYYMMDD.xlxs
	 08/10/2020 - new add 18353, fixed no quotes found issue
	 08/21/2020 - add orders to spreadsheet, change file name: NTS_1035_Open_Orders_Quotes_YYYYMMDD.xlxs,
*/

declare @Qcount18353 as int,
		@Opcount18353 as int,
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
 set @SubName = 'TPW-Inc.'

 -- test for open Orders & Quotes for 18353
select @Qcount18353 = COUNT(*) from d_Open_Quote_Summary where SalesRepName like '%18353%'
select @Opcount18353 = COUNT(*) from d_Open_Orders_Summary where SalesRepName like '%18353%'

--set no quotes found
set @noQuoteFound = ' '

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

set @OrderTable = 
	N'<h1><font color="#0000FF">Open Orders Summary</font></h1>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Orders</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenOrders,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Orders_Summary where SalesRepName like '%18353%' 
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
			from d_Open_Quote_Summary where SalesRepName like '%18353%' 
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

if @Qcount18353 >= 1 and @Opcount18353 >= 1
Begin
	set @fileNames = 'AC:\SQL_Out\TPW-Inc_18353_Open_Orders_Quotes_' + @sortDate + '.xlsx' 
End
else if  @Qcount18353 >= 1 and @Opcount18353 = 0
Begin 
	set @fileNames = 'BC:\SQL_Out\TPW-Inc_18353_Open_Orders_Quotes_' + @sortDate + '.xlsx' 
	set @OrderTable =  'A'
End
else if  @Qcount18353 = 0 and @Opcount18353 >= 1
Begin 
	set @fileNames = 'CC:\SQL_Out\TPW-Inc_18353_Open_Orders_Quotes_' + @sortDate + '.xlsx' 
	set @QuoteTable =  ''
End
else
Begin 
	set @fileNames = ''	
	set @QuoteTable = '' 
	set @OrderTable =  ''
	set @noQuoteFound = 'No Open Orders or Quotes Found.'
End

set @bodyText = @OrderTable + @QuoteTable + @noQuoteFound

select @Qcount18353[Q]
Select @Opcount18353[Orders]
Select @fileNames[F]
select @QuoteTable[QT]
select @OrderTable[OpT]
Select @bodyText[BT]
select @noQuoteFound[nqf]