-- update table  inv_tran_bin_detail

select *
from inv_tran_bin_detail
where bin = 'QUAR'

update inv_tran_bin_detail
set bin = 'DEAD'
where inv_tran_bin_detail_uid = 457789

select *
from inv_tran_bin_detail
where bin in ('QUAR','DEAD')