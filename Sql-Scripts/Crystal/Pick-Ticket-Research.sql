select customer_id,address_id,order_no,ship2_zip,order_date,h.date_created,h.date_last_modified,h.last_maintained_by,po_no,order_type,approved,cancel_flag,
completed,projected_order,validation_status,rma_flag,carrier_id,routed_eta_date,sr.route_code
from oe_hdr h
left join shipping_route sr
on h.shipping_route_uid = sr.shipping_route_uid
where order_no between 1094000 and 1094012



