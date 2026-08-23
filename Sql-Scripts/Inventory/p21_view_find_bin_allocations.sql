 select distinct document_no[PT_No]
 from p21_view_find_bin_allocations 
 where location_id = 410 and tran_type = 'PICK TICKET' and bin_cd  = 'AWOL'

select distinct document_no[PT_No]
from p21_view_find_bin_allocations 
where location_id = 410 and bin_cd  = 'AWOL'