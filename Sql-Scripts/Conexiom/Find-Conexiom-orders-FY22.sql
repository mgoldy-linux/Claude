select order_no, order_date
from oe_hdr
where taker = 'CXM' and order_date between '2021-07-01' and '2022-06-30'
