select *
from scheduled_job
where name like '%xml%'

select *
from p21_fnt_get_open_inbound_transactions (100,14487)

select *
from p21_fnt_sysjobs ()

exec sp_help p21_fnt_sysjobs 

select *
from p21_fnt_get_exchange_rate (1,10,Getdate())

exec p21_fn_code_description 928