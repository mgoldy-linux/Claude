select role,count(name)[# in Role]
from users u
join roles r
on u.role_uid = r.role_uid
where u.delete_flag = 'N'
group by role

select role,u.*
from users u
join roles r
on u.role_uid = r.role_uid
where u.delete_flag = 'N'
order by role


use play2;
-- check 400 location
select id, role, name, email_address,u.date_last_modified,default_branch,default_location_id
from users u
join roles r
on u.role_uid = r.role_uid
where u.delete_flag = 'N' and default_branch = 400
order by role