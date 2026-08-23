--https://sqlservergeeks.com/sql-server-error-15023-user-already-exists-in-current-database/#:~:text=The%20SQL%20Server%20error%2015023%20User%20already%20exists,is%20restored%20and%20are%20termed%20as%20orphaned%20users.

use P21Local2020;
go
sp_change_users_login 'Report' 

SELECT dp.name  As Orphan_Users
FROM sys.database_principals dp
left join sys.server_principals sp
ON dp.sid=sp.sid 
WHERE sp.name IS NULL 
AND dp.type='S' AND 
dp.name NOT IN ('guest','INFORMATION_SCHEMA','sys')