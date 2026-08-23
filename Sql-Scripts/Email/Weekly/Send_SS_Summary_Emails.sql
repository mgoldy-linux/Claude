/*
	02/11/2021 - for sending out weekly summary reports
	1 Sales-Summary-TGB_, gd
	2 Sales-Summary-DJ-Reps_
	3 Sales-Summary-Nobis-Industrial_ gb
	4 Sales-Summary-AF-Industrial_
	5 Sales-Summary-Bick-Products_
	6 Sales-Summary-Reliable-Pt_
	7 Sales-Summary-Simpson-Associates_ gb
	8 Sales-Summary-Rausch-Sales_ gb
	9 Sales-Summary-RGW-Sales_ gb
	10 Sales-Summary-Power-Associates_ gb
	11 Sales-Summary-RPT-Mexico_ gb
	12 Sales-Summary-Allied-Components_
	13 Sales-Summary-Industrial-Components_
	14 Sales-Summary-NTS_ gb
	15 Sales-Summary-TPW Inc._ gb
	02/22/21 fixed the too short @cc and loop too small
*/
declare 
		@counter as int,
		@dayNum as varchar(3),
		@monthName as varchar(20),
		@yearNum as varchar(5),
		@fullDate as varchar(35),
		@sortDate as varchar(10),
		@sortMonth as varchar(2),
		@fileNames as varchar(511),
		@cc as varchar(127),
		@toWho as varchar(511),
		@bodyText as varchar(MAX),
		@SubName as varchar(50),
		@Subject as NVARCHAR(125);
 
 set @counter = 1

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
-- set subject Name 
while @counter < 16
begin
if @counter = 1
	begin
	set @SubName = 'TGB Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-TGB_' + @sortDate + '.xlsx' 
	set @toWho = 'sales@tgbindustrial.com'
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 2
	begin
	set @SubName = 'DJ-Reps Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-DJ-Reps_' + @sortDate + '.xlsx' 
	set @toWho = 'sales@DJ-Reps.com'
	set @cc = 'lmitchell@solveindustrial.com;rlinke@solveindustrial.com'
	end
	else if @counter = 3
	begin
	set @SubName = 'Nobis-Industrial Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Nobis-Industrial_' + @sortDate + '.xlsx'
	set @toWho = 'sales@nobisindustrial.com' 
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 4
	begin
	set @SubName = 'AF-IndustrialWeekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-AF-Industrial_' + @sortDate + '.xlsx' 
	set @toWho = 'sales@af-industrial.com'
	set @cc = 'lmitchell@solveindustrial.com;rlinke@solveindustrial.com'
	end
	else if @counter = 5
	begin
	set @SubName = 'Bick-Products Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Bick-Products_' + @sortDate + '.xlsx' 
	set @toWho = 'Bicksales@planetkc.com'
	set @cc = 'lmitchell@solveindustrial.com;rlinke@solveindustrial.com'
	end
	else if @counter = 6
	begin
	set @SubName = 'Reliable-Pt Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Reliable-Pt_' + @sortDate + '.xlsx' 
	set @toWho = 'sales@reliable-pt.com'
	set @cc = 'lmitchell@solveindustrial.com;rlinke@solveindustrial.com'
	end
	else if @counter = 7
	begin
	set @SubName = 'Simpson-Associates Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Simpson-Associates_' + @sortDate + '.xlsx' 
	set @toWho = 'Info@skadrives.com'
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 8
	begin
	set @SubName = 'Rausch-Sales Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Rausch-Sales_' + @sortDate + '.xlsx' 
	set @toWho = 'rauschco7@gmail.com'
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 9
	begin
	set @SubName = 'RGW-Sales Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-RGW-Sales_' + @sortDate + '.xlsx' 
	set @toWho = 'robert@rgwsalescanada.com'
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 10
	begin
	set @SubName = 'Power-Associates Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Power-Associates_' + @sortDate + '.xlsx' 
	set @toWho = 'don@propowerreps.com;ryan@propowerreps.com'
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 11
	begin
	set @SubName = 'RPT-Mexico Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-RPT-Mexico_' + @sortDate + '.xlsx' 
	set @toWho = 'ramsler@eracos.com'
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 12
	begin
	set @SubName = 'Allied-Components Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Allied-Components_' + @sortDate + '.xlsx' 
	set @toWho = 'kevin@allied-components.com'
	set @cc = 'lmitchell@solveindustrial.com;rlinke@solveindustrial.com'
	end
	else if @counter = 13
	begin
	set @SubName = 'Industrial-Components Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-Industrial-Components_' + @sortDate + '.xlsx' 
	set @toWho = 'mmattis@icsreps.com;jmackenroth@icsreps.com'
	set @cc = 'lmitchell@solveindustrial.com;rlinke@solveindustrial.com'
	end
	else if @counter = 14
	begin
	set @SubName = 'NTS Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-NTS_' + @sortDate + '.xlsx' 
	set @toWho = 'mikekilliany@mac.com'
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	end
	else if @counter = 15
	begin
	set @SubName = 'TPW Inc. Weekly Sales Summary Report for '
	set @fileNames = 'C:\SQL_Out\Sales-Summary-TPW Inc._' + @sortDate + '.xlsx' 
	set @cc = 'lmitchell@solveindustrial.com;gdib@solveindustrial.com'
	set @toWho = 'info@tpwcorp.com'
	end
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

	set  @counter = @counter + 1

End