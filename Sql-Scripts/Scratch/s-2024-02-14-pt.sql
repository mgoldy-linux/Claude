select location_id, tracking_no,delete_flag, *
from oe_pick_ticket
where order_no = 1538243
--where pick_ticket_no = 2473140

select top 5 *
from oe_hdr
where order_no = 1538243

select top 5 *
from oe_hdr_salesrep
where order_number = 1538243

select  *
from oe_pick_ticket_detail
where pick_ticket_no = 2473140

select top 5 *
from p21_view_salutation

select top 5 *
from p21_view_clippership_return_10004
where pick_ticket_no = 2473140
,
      ptshipment.shipment_id,
      oe_pick_ticket.tracking_no


-- empty
/*
select top 5 *
from shipment
*