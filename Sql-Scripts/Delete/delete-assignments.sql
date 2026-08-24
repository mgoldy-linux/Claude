--Use P21Dev3;
use Play2;

-- Top of the page assembly header 
SELECT design.design_uid,design.name,design.location,design.description,assignment.assignment_type,assignment.assignee,assignment.role_uid,(SUBSTRING(location, 1, CHARINDEX('.', location)-1) + '.' + REVERSE(SUBSTRING(REVERSE(location), 1, CHARINDEX('.', REVERSE(location))- 1))) AS windowname_dwname  
FROM design  
INNER JOIN assignment ON (design.design_uid = assignment.design_uid)
where name = 'Assembly_Maintenance_General (11.29.2022-RS)'
order by assignee

select *
from assignment
where design_uid = 182 and assignment_uid != 9399

delete
from assignment
where design_uid = 182 and assignment_uid != 9399

select *
from assignment
where design_uid = 182 

-- bottom of the page component
SELECT design.design_uid,design.name,design.location,design.description,assignment.assignment_type,assignment.assignee,assignment.role_uid,(SUBSTRING(location, 1, CHARINDEX('.', location)-1) + '.' + REVERSE(SUBSTRING(REVERSE(location), 1, CHARINDEX('.', REVERSE(location))- 1))) AS windowname_dwname  
FROM design  
INNER JOIN assignment ON (design.design_uid = assignment.design_uid)
where name = 'Assembly_Maintenance (06.01.2023-RS)'
order by assignee

select *
from assignment
where design_uid = 245 and role_uid != 30

delete
from assignment
where design_uid = 245 and role_uid != 30

select *
from assignment
where design_uid = 245 and role_uid != 30
