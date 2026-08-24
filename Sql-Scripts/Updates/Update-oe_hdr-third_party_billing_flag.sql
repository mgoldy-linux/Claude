-- 08/03/2022 - email from debbie

--use Play2;  -- test on 08/04/2022
use P21;

select third_party_billing_flag,address_id,order_no,order_date,po_no
from oe_hdr 
where completed = 'N' and cancel_flag = 'N' and projected_order = 'N' and third_party_billing_flag = 'S' and customer_id = 10782

Update oe_hdr
set third_party_billing_flag = 'B'
where completed = 'N' and cancel_flag = 'N' and projected_order = 'N' and third_party_billing_flag = 'S' and customer_id = 10782


select third_party_billing_flag,address_id,order_no,order_date,po_no
from oe_hdr
where completed = 'N' and cancel_flag = 'N' and projected_order = 'N' and third_party_billing_flag = 'S' and customer_id = 10782