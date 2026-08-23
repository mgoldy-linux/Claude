select *
from inv_tran
where on_hand_before_trans = 0 and location_id = 100 and trans_type = 'po' and date_created > '2023-07-01'

select *
from inv_mast
where inv_mast_uid = 20944

select *
from inv_tran
where location_id = 100 and inv_mast_uid = 20944
