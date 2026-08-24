--  no bin might have cause this issue?
-- need to turn foreign key constraint on inv_tran_bin_detail

use P21Play;

select count(bin)[numOfBefore]
from dbo.inv_tran_bin_detail
where location_id = 100 and bin = 'NO PRIMARY'

update dbo.inv_tran_bin_detail
set bin = 'NO_PRIMARY'
where location_id = 100 and bin = 'NO PRIMARY'

select count(bin)[numOfAfter]
from dbo.inv_tran_bin_detail
where location_id = 100 and bin = 'NO PRIMARY'

/*
select count(bin)[numOfBefore]
from dbo.inv_bin
where location_id = 100 and bin = 'NO PRIMARY'

Update dbo.inv_bin
set bin = 'NO_PRIMARY'
where location_id = 100 and bin = 'NO PRIMARY'

select count(bin)[numOfAfter]
from dbo.inv_bin
where location_id = 100 and bin = 'NO PRIMARY'
*/
