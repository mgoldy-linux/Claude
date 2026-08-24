select top 500* 
from dbo.inv_bin ib
where bin in ('KENNIS A','PLT-0232')
order by date_last_modified desc


select distinct row_status_flag
from dbo.inv_bin ib
order by date_last_modified desc

select top 5 *
from code_p21
where code_no in (1037,1438,1439)

select top 25 *
from dbo.bin 
where delete_flag = 'y'
order by date_last_modified desc

select top 50 it.*
from dbo.inv_tran it
join dbo.inv_mast m
on it.inv_mast_uid = m.inv_mast_uid
where location_id = 100 and item_id = '2101100343'
order by date_last_modified desc 


select top 5 *
from bin
where bin_id = 'PLT-0232'


select *
from inv_mast
where inv_mast_uid in (67323,14333,60423,100937)

select top 5*
from audit_trail
where table_changed like '%inv_%'
order by date_created desc

select top 5*
from audit_trail_support
order by date_created desc

select top 60*
from inv_tran_bin_detail
where bin in ('KENNIS A','PLT-0232')