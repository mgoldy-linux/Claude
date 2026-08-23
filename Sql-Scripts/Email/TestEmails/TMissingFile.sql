 /*
	05/20/2020 - test email Open quote  Monday Morning at 6:17 AM
	 @recipients = Bicksales@planetkc.com, CC = dhampton@ptintl.com 
	 File names: Bick-Products_1023_Open_Quotes_YYYYMMDD.xlxs; Bick-Products_10659_Open_Quotes_YYYYMMDD.xlxs
	06/29/2020 - change dhampton@ptintl to rlinke@ptintl.com

*/
declare @Qcount1023 as int,
		@Qcount10659 as int,
		@Opcount1023 as int,
		@Opcount10659 as int,
		@dayNum as varchar(3),
		@dayNum2 as varchar(3),
		@monthName as varchar(20),
		@monthName2 as varchar(20),
		@yearNum as varchar(5),
		@yearNum2 as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@noQuoteFound as varchar(50),
		@bodyText as varchar(MAX),
		@QuoteTable as varchar(MAX),
		@OrderTable as varchar(MAX),
		@SubName as varchar(50),
		@Subject as NVARCHAR(125),
		@f1023 as varchar(255),
		@f10659 as varchar(255),
		@fileNames as varchar(511);
 
 -- set subject Name 
 set @SubName = 'Bick-Products'
 
 -- test for open qoutes for 1023
 select @Qcount1023 = COUNT(*) from d_Open_Quote_Summary where SalesRepName like '%23%'
 select @Opcount1023 = COUNT(*) from d_Open_Orders_Summary where SalesRepName like '%23%'
  -- test for open qoutes for 10659
 select @Qcount10659 = COUNT(*) from d_Open_Quote_Summary where SalesRepName like '%659%'
 select @Opcount10659 = COUNT(*) from d_Open_Orders_Summary where SalesRepName like '%659%'

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
	N'<h4><font color="#0000FF">Open Orders Summary</font></h4>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Quotes</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenOrders,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Orders_Summary where SalesRepName like '%23%' or  SalesRepName like '%659%'
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

set @QuoteTable = 
	N'<h4><font color="#EE82EE">Open Quotes Summary</font></h4>' +
	N'<table border="1">' +
	N'<tr align="center"><th>Sales Rep Name</th><th>Number of Open Quotes</th><th>Total Value</th></tr>' +
		cast ((select "td/@align" = 'center',SalesRepName,	'',
					  "td/@align" = 'center',NumberOpenQuotes,		'',
					  "td/@align" = 'center',TotalValue
			from d_Open_Quote_Summary where SalesRepName like '%23%' or  SalesRepName like '%659%'
			order by TotalValue desc
			for XML Path('tr'), Type
			) AS NVARCHAR(MAX)) + 
			N'</table>'

			IF OBJECT_ID('tempdb..#DirectoryTree')IS NOT NULL
      DROP TABLE #DirectoryTree;
CREATE TABLE #DirectoryTree (
       id int IDENTITY(1,1)
      ,subdirectory nvarchar(512)
      ,depth int
      ,isfile bit);
INSERT #DirectoryTree (subdirectory,depth,isfile)
EXEC master.sys.xp_dirtree 'C:\SQL_Out',1,1;

SELECT @f1023 = subdirectory FROM #DirectoryTree
WHERE isfile = 1 AND subdirectory like  '%1023%'

SELECT @f10659 = subdirectory FROM #DirectoryTree
WHERE isfile = 1 AND subdirectory like  '%10659%.xlsx'

if @f1023 is not null 
begin
	set @f1023 = 'C:\SQL_Out\Bick-Products_1023_Open_Orders_Quotes_' + @sortDate + '.xlsx'
end
else
begin
	set @f1023 = 'C:\SQL_Out\Bick-Products_1023_No_Open_Orders_Quotes_' + @sortDate + '.txt'
end

if @f10659 is not null
begin
	set @f10659 = 'C:\SQL_Out\Bick-Products_10659_Open_Orders_Quotes_' + @sortDate + '.xlsx'
end
else
begin
set  @f10659 = 'C:\SQL_Out\Bick-Products_10659_No_Open_Orders_Quotes_' + @sortDate + '.txt'
end

set @fileNames = @f1023 + ';' + @f10659 

set @Subject = @SubName + ' Open Orders & Quotes Report for ' + @fullDate  + '.'
set @bodyText = @OrderTable + @QuoteTable -- + @noQuoteFound until fix logic on orders and quotes found

select @f1023[23]
select @f10659[659]
Select @fileNames[fn]

EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'mgoldyn@ptintl.com',
	  --@copy_recipients = 'rlinke@ptintl.com ',
      --@blind_copy_recipients = 'mgoldyn@ptintl.com',
      @reply_to = 'mgoldyn@ptintl.com',
      @from_address = 'mgoldyn@ptintl.com',
      @subject = @Subject,
      @body = @bodyText,
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'HTML';
