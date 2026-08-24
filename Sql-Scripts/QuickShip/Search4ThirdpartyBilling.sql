select order_no, ups_code,third_party_billing_flag,source_location_id,carrier_id
from oe_hdr
where third_party_billing_flag = 'T' and source_location_id = 100
order by date_created desc