Declare @Path nvarchar(511) = 'C:\SQL_Out',
		@fileNames as varchar(255);


exec xp_Dirtree @Path,1,1 

-- find sql aerver information
exec xp_msver

  