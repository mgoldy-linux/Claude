select suser_sname(owner_sid) as 'Owner', state_desc, *
from sys.databases

SELECT name AS Login_Name, type_desc AS Account_Type,is_disabled,create_date, modify_date,default_database_name
FROM sys.server_principals 
WHERE  TYPE IN ('U', 'S', 'G')
and name not like '%##%'
ORDER BY name, type_desc