-- need to update address 9999 in P21 to make this work
--use P21train;
use P21;
select *
from dbo.vendor
where vendor_id_string = 112098

update dbo.vendor
set vendor_id = 9999
where vendor_id_string = 112098

select *
from dbo.vendor
where vendor_id_string = 112098

select *
from dbo.vendor
where vendor_id = 9999

update dbo.vendor
set vendor_id_string = 9999
where vendor_id = 9999

select *
from dbo.vendor
where vendor_id = 9999