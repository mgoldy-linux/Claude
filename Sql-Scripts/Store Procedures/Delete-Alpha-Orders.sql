--use P21Sand;
use P21;
---use Play2;

select *
from oe_hdr
where order_no not like '%[^A-Za-z]%'

exec p21_delete_alpha_orders

select *
from oe_hdr
where order_no not like '%[^A-Za-z]%'
