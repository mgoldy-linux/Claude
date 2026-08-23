Declare @f1023 as varchar(255),
		@f10659 as varchar(255),
		@fileNames as varchar(255);


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
WHERE isfile = 1 AND subdirectory like  '%10679%'

set  @fileNames = 'C:\SQL_Out\' + @f1023 + ';' + 'C:\SQL_Out\'  + @f10659

EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'P21Alerts',
      @recipients = 'mgoldyn@ptintl.com',
	  --@copy_recipients = 'rlinke@ptintl.com ',
      --@blind_copy_recipients = 'mgoldyn@ptintl.com',
      @reply_to = 'mgoldyn@ptintl.com',
      @from_address = 'mgoldyn@ptintl.com',
      @subject = 'Test 2 Files',
      @body = 'testing 1 2 3',
      @file_attachments = @fileNames,
	  @importance = 'normal',
	  @body_Format = 'HTML';
