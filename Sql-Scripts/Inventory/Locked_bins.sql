select bin_id, pick_locked_flag[pick_locked]
from bin
where location_id = 300 and pick_locked_flag = 'Y' and bin_id != 'HOLD'


select bin_id, pick_locked_flag[pick_locked],put_locked_flag
from bin
where location_id = 100 and bin_id = '3118A'