-- Grainger from scratch

Select oh.order_no,ol.line_no,ol.customer_part_number,m.item_id,item_desc,oh.location_id[Sales-Loc],ol.ship_loc_id--,opt.pick_ticket_no,print_date--,COALESCE(clip.shipped_date,opt.ship_date) c_ship_date,requested_date
from oe_hdr oh
join oe_line ol
on oh.order_no = ol.order_no
join inv_mast m
on ol.inv_mast_uid = m.inv_mast_uid
--join oe_pick_ticket opt
--on oh.order_no = opt.order_no 
--join  clippership_return_10004 clip
--on clip.pick_ticket_no = opt.pick_ticket_no and clip.invoice_no= opt.invoice_no
where oh.order_no = 1538243 --and line_no = 1


/*
select *
from oe_line
where order_no = 1538243
*/

select *
from oe_pick_ticket
where order_no = 1538243

select shipped_date,*
from clippership_return_10004
where pick_ticket_no = 2482025

select shipped_date,*
from  p21_view_clippership_return_10004
where pick_ticket_no = 2482025

select ship_date,*
from oe_pick_ticket
where pick_ticket_no = 2482025
