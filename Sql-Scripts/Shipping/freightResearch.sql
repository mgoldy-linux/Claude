select distinct third_party_billing_flag
from ship_to

select *
from invoice_hdr


select *
from oe_hdr
--where freight_out > 0
where order_no = 1016470

select *
from oe_line
where order_no = 1016470


select *
from order_totals
where oe_hdr_uid = 16436

select *
from invoice_hdr
where freight > 0
--order_no = '1016470'
-- freight out, also need ship date to elimate mutliple lines case
select *
from oe_pick_ticket
where order_no = 1016470