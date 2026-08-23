-- need to division first, disable fk

--use P21train;
use P21;

select *
from dbo.division
where division_id = 112098
order by date_created desc

update dbo.division 
set supplier_id = 9999
where division_id = 112098

select *
from dbo.division
where division_id = 112098
order by date_created desc

select *
from dbo.supplier
where supplier_name = 'Unassigned'
order by date_created desc

Update dbo.supplier
set supplier_id = 9999
where supplier_name = 'Unassigned'

select *
from dbo.supplier
where supplier_name = 'Unassigned'
order by date_created desc
