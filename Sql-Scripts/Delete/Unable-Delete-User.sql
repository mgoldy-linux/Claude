-- Doesn't work due to conflicts
select *
from dbo.rf_terminal
where current_user_id = 'KATHY.GAUSE'

delete 
from dbo.rf_terminal
where current_user_id = 'KATHY.GAUSE'

select *
from dbo.rf_terminal
where current_user_id = 'KATHY.GAUSE'

select *
from users
where id = 'KATHY.GAUSE'

delete 
from dbo.users
where id = 'KATHY.GAUSE'

select *
from users
where id = 'KATHY.GAUSE'




