use P21Sand;

Declare @dayDate as varchar(10);

set @dayDate =  convert(varchar(10), getdate(), 120)

select *
from dbo.inv_loc
where last_maintained_by = 'mgoldyn-sql' and date_last_modified > @dayDate

select *
from dbo.inv_bin
where last_maintained_by = 'mgoldyn-sql' and date_last_modified > @dayDate

select *
from dbo.inventory_supplier_x_loc
where last_maintained_by = 'mgoldyn-sql' and date_last_modified > @dayDate