--- didn't work

select *
from pc_user_def
where user_skey > 1114

insert into pc_user_def (user_skey,user_id,first_name,last_name,email_address)
values(1116,'TBRADY','Tom','Brady','tbrady@ptintl.com')

select *
from pc_user_def
where user_skey > 1114

select *
from users
order by date_created desc

exec sp_helpconstraint pc_user_def