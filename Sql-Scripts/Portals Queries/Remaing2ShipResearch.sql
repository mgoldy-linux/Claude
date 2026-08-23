-- sample pts: 2008802,2008803,2057040,2057044,2087341
-- sample pt: 2022808
-- sample pts: 2026319,2029406
-- sample pts: 2007287,2013564,2027356,2050933
-- remaing quantity is for the pick

select h.pick_ticket_no, h.order_no,  print_date, a.name, tracking_no,ship_date,invoice_no,printed_flag,oe_line_no,item_id,location_id,ol.qty_ordered,ship_quantity,ol.qty_canceled,ol.complete,(ol.qty_ordered - ol.qty_canceled -ship_quantity)[Remaining_quantity]
from oe_pick_ticket h
join oe_pick_ticket_detail d
on h.pick_ticket_no = d.pick_ticket_no
join inv_mast im
on d.inv_mast_uid = im.inv_mast_uid
join oe_line ol
on h.order_no = ol.order_no and ol.line_no = d.oe_line_no 
join address a
on h.carrier_id = a.id
where h.pick_ticket_no in (2007287,2013564,2027356,2050933) and ol.cancel_flag = 'N' 
group by h.pick_ticket_no, h.order_no,  print_date, a.name, tracking_no,ship_date,invoice_no,printed_flag,oe_line_no,item_id,location_id,ol.qty_ordered,ship_quantity,ol.qty_canceled,ol.complete
order by oe_line_no

/*
select *
from oe_pick_ticket_detail
where pick_ticket_no = 2095450

select line_no,complete, *
from oe_line
where order_no = 1031046

select *
from carrier
where carrier_id = 16323
*/