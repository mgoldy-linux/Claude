-- requires disabling fk_inv_bin_bin prior to running update

Select *
from bin
where bin_uid = 2477

update bin
set bin_id = 'DEAD'
where bin_uid = 2477

select bin_id
from bin
where bin_uid = 2477

