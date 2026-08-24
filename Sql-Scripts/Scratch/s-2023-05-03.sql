select *
from vessel_receipts_hdr_ud

use [P21Play2021.1.4420Local];
select st.ship_to_id,a.name,a.phys_state,default_branch
from ship_to st
join address a
on st.ship_to_id = a.id
where customer_id = 61457
order by name


select *
from ship_to_salesrep sts
join ship_to st
on sts.ship_to_id = st.ship_to_id 
where salesrep_id = 27833 and customer_id = 48269