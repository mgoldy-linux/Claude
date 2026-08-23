use NAVPROD;

select No_,Description,[Item UPC_EAN Number]
from [NAVPROD].[dbo].[PT International Corp_$Item]
where No_ like '%RM'
order by No_
--where No_ = 'UC21470MMRM'

