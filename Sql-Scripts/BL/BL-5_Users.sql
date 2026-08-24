Use play2;

select *
from users
where default_branch = 400 and id in ('CMURRAY','JDANIELHAYNES','JSCALA','LSTALLONE','SHOUGHTON') and delete_flag = 'N'