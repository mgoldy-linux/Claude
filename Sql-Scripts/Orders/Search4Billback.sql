select order_no, date_created, *
from oe_hdr
where freight_code_uid = 2 and date_created < '2021-02-27' and location_id = 100 and carrier_id = 16327
--order by order_no desc