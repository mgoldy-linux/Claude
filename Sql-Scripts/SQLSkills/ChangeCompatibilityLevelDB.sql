SELECT compatibility_level,database_id,name
FROM sys.databases

Alter Database [P21Local2019]
set compatibility_level = 140
go

SELECT compatibility_level,database_id,name
FROM sys.databases