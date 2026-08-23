-- 03/30/22  per email from Billy Wolfe
-- tested on Play first
--Use P21Play;
Use P21;

select order_no, customer_id,ship2_name
from oe_hdr
where address_id = 36091 and completed = 'N' and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

update oe_hdr
set ship2_Name = 'TIMKEN CROSSVILL E- COLINX LLC'
where address_id = 36091 and completed = 'N' and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'

select order_no, customer_id,ship2_name, order_date
from oe_hdr
where  completed = 'N' and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N' and order_date > '2022-03-02'

select order_no, customer_id,ship2_name
from oe_hdr
where address_id = 36091 and completed = 'N' and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'