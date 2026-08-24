/*
	02/11/2021 - for sending out weekly summary reports
*/
declare @dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(511),
		@bodyText as varchar(MAX),
		@SubName as varchar(50),
		@Subject as NVARCHAR(125);
 
 -- set subject Name 
 set @SubName = 'TGB Weekly Sales Summary Report for '
 
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

set @fileNames = 'C:\SQL_Out\Sales-Summary-TGB' + @sortDate + '.xlsx' 

set @Subject = @SubName + @fullDate  + '.'
set @bodyText = 'Sales summary report for your review.'

EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      --@recipients = 'sales@tgbindustrial.com',
      --@copy_recipients = 'gdib@solveindustrial.com',
      @blind_copy_recipients = 'mgoldyn@solveindustrial.com',
      @reply_to = 'it@ptintl.com',
      @from_address = 'it@ptintl.com',
      @subject = @Subject,
      @body = @bodyText,
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'text';