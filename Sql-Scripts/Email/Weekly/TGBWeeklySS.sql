declare 
		@counter as int,
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(511),
		@cc as varchar(50),
		@toWho as varchar(511),
		@bodyText as varchar(MAX),
		@SubName as varchar(50),
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
set @bodyText = 'Sales summary report for your review.'

set @SubName = 'TGB Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-TGB_20210214.xlsx' 
	set @toWho = 'sales@tgbindustrial.com'
	set @cc = 'gdib@solveindustrial.com'
	set @sortDate = @yearNum + @sortMonth + @dayNum
	set @Subject = @SubName + @fullDate  + '.'


EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = @toWho,
      @copy_recipients = @cc,
      @blind_copy_recipients = 'mgoldyn@solveindustrial.com',
      @reply_to = 'it@ptintl.com',
      @from_address = 'eservice@ptintl.com',
      @subject = @Subject,
      @body = @bodyText,
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'text';