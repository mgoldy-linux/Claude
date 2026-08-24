-- requires disabling fk_inv_bin_bin prior to running update
-- reference Update_Inv_bin_BinNane.ps1

select *
from inv_bin
where  inv_bin_uid = 70408

update inv_bin
set bin = 'DEAD'
where inv_bin_uid = 70408

select bin
from inv_bin
where  inv_bin_uid = 70408

select *
from inv_bin
where bin = 'QUAR'

select *
from bin 
where bin_id = 'DEAD'