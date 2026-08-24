select id,name,mail_city,mail_state
from address
where mail_state like '[MV]%'
order by mail_city

select id,name,mail_city,mail_state,central_phone_number
from address
where mail_state like '[N-R]%'
order by mail_city

select id,name,mail_city,mail_state,central_phone_number
from address
where central_phone_number like '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'

-- ^ is the not operator
select id,name,mail_city,mail_state,central_phone_number
from address
where mail_state like '[^N-Z]%'
order by mail_city