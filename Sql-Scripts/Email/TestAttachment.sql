/*
	Attachment file C:\temp\SQL_Out\DH_Sales_Report_20200413.xlsx is invalid. because I'm logged in as administrator?

*/
declare @dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(100),
		@Subject as NVARCHAR(125);

select @dayNum = DATENAME(DAY,GetDate())
select @monthName = DATENAME(MONTH,GetDate())
select @yearNum = DATENAME(YEAR,GetDate())
select @sortMonth = Month(GetDate())

Select @fullDate =  @monthName + ' ' + @dayNum + ', '  + @yearNum

If @sortMonth < 10
set @sortDate = @yearNum + '0' + @sortMonth + @dayNum
else
set @sortDate = @yearNum +  @sortMonth + @dayNum

set @fileNames = 'C:\temp\SQL_Out\DH_Sales_Report_' + @sortDate + '.xlsx' + ';' + 'C:\temp\SQL_Out\DH_Quotes_Report_' + @sortDate + '.xlsx'

select @fileNames

select @Subject = @fullDate + ' Daily Excel Files for Doug Hampton'

EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      --@recipients = 'dhampton@ptintl.com',
      @blind_copy_recipients = 'mgoldyn@ptintl.com',
      @reply_to = 'mgoldyn@ptintl.com',
	  @from_address = 'it@ptintl.com',
	  @subject = @Subject,
      @body = 'Please see attached files',
      @file_attachments = @fileNames,
	  @importance = 'private';
	 