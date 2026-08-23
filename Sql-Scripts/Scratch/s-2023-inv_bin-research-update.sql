select *
from inv_bin 
where inv_mast_uid in (7225,10015)

update dbo.inv_bin 
set bin = 'NO_PRIMARY'
where inv_mast_uid in (10007,10015) and bin = 'NOBIN'
 
select *
from inv_bin 
where inv_mast_uid = 7225

select *
from dbo.inv_tran_bin_detail
where inv_mast_uid = 7225 
order by date_last_modified desc 

exec p21_rebuild_primary_bin 2101007223, 100

-- (10007, 100, NO_PRIMARY, 1

select *
from inv_bin 
where inv_mast_uid = 10007