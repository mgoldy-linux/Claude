select *
from audit_trail
where date_created > '2021-01-21'
order by date_created desc
-- distinct  object_type  -- procedure,table, view, column
select *
from p21_database_changes
where version = '20.2.4102.C.045' and object_type = 'Procedure'

select *
from p21_database_changes
where version = '20.2.4102.c.010' and object_type = 'column'
order by object_name

select *
from p21_dblevel

select *
from db_sql
order by date_sql_executed desc


select *
from report_parameter

select *
from apinv_line_edit_audit_trail
