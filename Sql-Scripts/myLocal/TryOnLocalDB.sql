--https://database.guide/how-to-fix-server-is-not-configured-for-data-access-in-sql-server/#:~:text=The%20%E2%80%9CServer%20is%20not%20configured%20for%20DATA%20ACCESS%E2%80%9D,of%20the%20server%20that%20you%E2%80%99re%20trying%20to%20access.

SELECT * FROM OPENQUERY([MGOLDYN-LAPTOP], 'exec p21local.[dbo].[p21_get_qty_to_make] [UCFCX08-24], 28007, 100, 0;');
--exec p21.dbo.p21_get_qty_to_make([UCFCX08-24], 28007, 100, 0)
SELECT 
  name,
  is_data_access_enabled 
FROM sys.servers;

EXEC sp_helpserver;

EXEC sp_serveroption
  @server = 'MGOLDYN-LAPTOP',
  @optname = 'DATA ACCESS',
  @optvalue = 'TRUE';

  SELECT COLUMN_NAME,TYPE_NAME,PRECISION,LENGTH
FROM OPENQUERY ([MGOLDYN-LAPTOP],'EXEC WideWorldImporters.[dbo].[sp_columns] Cities, Application;');