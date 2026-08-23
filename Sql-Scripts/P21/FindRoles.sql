-- form Jeff: Can you do a query of user and show me the user id, name, and role?

select id,name,role
from users u
join roles r
on u.role_uid = r.role_uid
where u.delete_flag = 'N'