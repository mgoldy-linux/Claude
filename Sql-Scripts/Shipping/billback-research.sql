use P21;

select top 50 *
from oe_hdr 
where third_party_billing_flag = 'B' and location_id like '5%'
order by date_created desc

select top 6*
from p21_view_clippership_return_10004

select freight_out, *
from dbo.oe_pick_ticket
where pick_ticket_no = 2374402

select *
from oe_hdr 
where order_no = 1460265

select *
from oe_hdr 
where order_no = 1460265

select *
from freight_code