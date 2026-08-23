--- check conexiom
-- where po_no = '7234147' - failed customer id - update xref om 12/10/20
-- where po_no = '4502880711' - failed carrier id -
-- created powershell script checkorder for this

declare @Order_no int;

select h.order_no,customer_id,order_date,ship2_name,po_no,source_location_id,h.approved,taker
from oe_hdr h
where po_no = 'MA20-00378530'

set @Order_no = (select order_no from oe_hdr where po_no = 'MA20-00378530')

select ivs.upc_code,im.upc_or_ean_id,short_code,item_id,item_desc,l.line_no,convert(int,l.qty_ordered)[qty_ordered],im.class_id2,assembly
from oe_line l
join inv_mast im
on l.inv_mast_uid = im.inv_mast_uid
join inventory_supplier ivs
on im.inv_mast_uid = ivs.inv_mast_uid
where order_no = @Order_no
order by l.line_no

