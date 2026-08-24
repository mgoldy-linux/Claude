select *
from bin
where bin_id = 'O BIN 1304'

select *
from dbo.inv_mast
where item_id = '2101033243'

select *
from dbo.inv_loc_stock_status
where inv_mast_uid = 33245

select *
from dbo.inv_loc 
where inv_mast_uid = 33245 and location_id = 300

select top 7 *
from inv_bin
where bin in ('O BIN 1-9','O BIN 1-10','O BIN 6-1','O BIN 2-14','O BIN 1304')

update inv_bin
set row_status_flag = 1037, last_maintained_by = 'mgoldyn-sql'
where location_id = 300 and bin = 'O BIN 1-9'

select *
from dbo.inv_bin 
where location_id = 300 and row_status_flag = 1438 and bin != 'HOLD'
order by bin


select  *
from inv_bin
where bin ='O BIN 1304'