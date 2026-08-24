select *
from audit_trail
where date_created > '2021-01-21'
order by date_created desc

select *
from p21_database_changes
where version like '20.2%' and object_type = 'Procedure'
order by object_name

select *
from report_parameter