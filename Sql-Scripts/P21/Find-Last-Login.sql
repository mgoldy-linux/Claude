use master
select spid, substring(nt_username,1,30) NT_Login,
substring(loginame,1,30) DB_Login,
substring(name,1,30) DB,
substring(hostname,1,30) Host,
login_time,
last_batch
from master..sysprocesses
inner join master..sysdatabases ON master..sysdatabases.dbid =
master..sysprocesses.dbid
where master..sysprocesses.program_name like
'PXXI/SQLCA/%'
and master..sysprocesses.ecid = 0
order by nt_username