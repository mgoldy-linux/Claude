select customer_id, territory_id, territory_desc
from territory_x_customer txc
join territory t
on txc.territory_uid = t.territory_uid
where t.row_status_flag = 704


select *
from territory

use P21;

select *
from oe_hdr 
where order_no = '1448347'