-- source of GL
use WQMetaData;

select *
from vwGLBalances
where account_no = 13020000100 and year_for_period = 2021
order by year_for_period, period