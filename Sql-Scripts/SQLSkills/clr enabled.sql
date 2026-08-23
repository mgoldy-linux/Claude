/*
	Fix for error message:
	SQLDBCode: 50000
	Select Error: SQLSTATE = 42000
	Microsoft OLE DB Provider for SQL Server
	Execution of user code in the .NET Framework is disabled. Enable "clr enabled" configuration option.
*/


-- show advanced options
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
 
-- enable clr enabled
EXEC sp_configure 'clr enabled', 1
GO
RECONFIGURE
GO
 
-- check if it has been changed
EXEC sp_configure 'clr enabled'
GO
 
-- hide advanced options
EXEC sp_configure 'show advanced options', 0
GO
RECONFIGURE
GO
