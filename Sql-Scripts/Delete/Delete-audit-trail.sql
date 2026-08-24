/*
(1 row affected)
Msg 9002, Level 17, State 2, Line 7
The transaction log for database 'P21Sand' is full due to 'LOG_BACKUP'.
*/

-- before
select COUNT (*)[NumOfRecs]
from audit_trail
where date_created < '2023-09-01'

-- delete statement
delete dbo.audit_trail
where date_created < '2023-09-01'

-- After
select COUNT (*)[NumOfRecs]
from audit_trail
where date_created Between '2023-09-01' and GETDATE()
