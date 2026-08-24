use P21;

select c.pick_ticket_no, total_charge, p.order_no, p.freight_out,h.freight_out,h.third_party_billing_flag,h.ups_code,p.tracking_no,c.tracking_no,h.carrier_id,p.ship_date
from  p21_view_clippership_return_10004 c
join oe_pick_ticket p 
on c.pick_ticket_no = p.pick_ticket_no
join oe_hdr h
on h.order_no = p.order_no
where p.location_id = 100 and projected_order = 'N' and h.delete_flag = 'N' and h.third_party_billing_flag = 'T' and h.carrier_id in (16252,16253,16269,16370)
order by shipped_date desc

/*
-- 2133758
select *
from oe_pick_ticket
where pick_ticket_no = 2133758

select carrier_id
from oe_hdr
where order_no = 1157613

select id, name
from address
where carrier_flag = 'Y'
*/