
declare @bodyText as varchar(MAX),
		@Subject as NVARCHAR(125);
 
 -- set subject Name 
set @Subject = 'Test email from Solve Industrial Motion Group'

set @bodyText = 'This is a test email from Solve Industrial Motion Group, please reply if you recieved this email.'


EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'sales@nobisindustrial.com',
	  --@copy_recipients = 'ryan.linke@solveindustrial.com ',
      @blind_copy_recipients = 'mark.goldyn@solveindustrial.com',
      @reply_to = 'reports@solveindustrial.com',
      @from_address = 'eservice@solveindustrial.com',
      @subject = @Subject,
      @body = @bodyText,
      @importance = 'normal',
	  @body_Format = 'HTML';