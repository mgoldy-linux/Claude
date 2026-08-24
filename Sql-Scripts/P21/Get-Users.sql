use P21train;

select *
from users
where default_location_id = 601

select *
from users
where default_location_id is null

select *
from users
where default_location_id is not null and default_location_id != 601
order by default_location_id

Use P21Train; --P21Dev3; --Play2; --P21Play; --P21;

Select *
from users

Select *
from dbo.users 
where delete_flag = 'N'