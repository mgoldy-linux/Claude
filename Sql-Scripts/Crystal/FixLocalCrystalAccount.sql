/* received these errors message
Msg 15401, Level 16, State 2, Line 1
Windows NT user or group 'admin' not found. Check the name again.
Msg 15401, Level 16, State 2, Line 1
Windows NT user or group 'tpcx' not found. Check the name again.
Msg 15401, Level 16, State 2, Line 1
Windows NT user or group 'EDI' not found. Check the name again.
Msg 33017, Level 16, State 1, Line 1
Cannot remap a user of one type to a login of a different type. For example, a SQL user must be mapped to a SQL login; it cannot be remapped to a Windows login.
Msg 15401, Level 16, State 2, Line 1
Windows NT user or group 'localC' not found. Check the name again.

*/

-- fix all orphan users in database
-- where username=loginname
DECLARE @orphanuser varchar(50)
DECLARE Fix_orphan_user CURSOR FOR
SELECT dp.name  As Orphan_Users
FROM sys.database_principals dp
left join sys.server_principals sp
ON dp.sid=sp.sid 
WHERE sp.name IS NULL 
AND dp.type='S' AND 
dp.name NOT IN ('guest','INFORMATION_SCHEMA','sys')

OPEN Fix_orphan_user
FETCH NEXT FROM Fix_orphan_user
INTO @orphanuser WHILE @@FETCH_STATUS = 0
BEGIN

EXECUTE('ALTER USER ' + @orphanuser + ' WITH LOGIN = ' + @orphanuser)

FETCH NEXT FROM Fix_orphan_user
INTO @orphanuser
END
CLOSE Fix_orphan_user
DEALLOCATE Fix_orphan_user