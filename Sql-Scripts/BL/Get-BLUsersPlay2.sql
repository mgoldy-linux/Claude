use Play2;

select *
from Users
where default_branch = 400 and delete_flag = 'N' 


select User_id, first_name, last_name
from pc_user_def p
join users u
on p.user_id = u.id
where default_branch = 400 and u.delete_flag = 'N'


-- 07-17-2022
use Play2;

select *
from Users
where default_branch = 400 and delete_flag = 'N' and id not in ('CMURRAY','JDANIELHAYNES','JSCALA','LSTALLONE','SHOUGHTON','DHAVRANEK','TGLIGANIC','RROSENBERG')
