-- goal print labels from order number
-- 

with getOrders
as
(
	select order_no,ship2_name
	from oe_hdr
	where projected_order = 'N'
)
select ol.order_no[Order Number],im.item_id[Part Number],ol.customer_part_number[Customer Part Number],im.item_desc[Description],im.extended_desc[Ext desc], im.upc_or_ean_id[UPC],complete
from oe_line ol
join getOrders g
on g.order_no = ol.order_no
join inv_mast im
on ol.inv_mast_uid = im.inv_mast_uid 
where ol.complete = 'N' 
order by ol.order_no desc

--where order_no = '1073249'

select order_no,item_id,qty_ordered,line_no,supplier_id,a.id,a.phys_country,extended_desc,customer_part_number,upc
from p21_order_view ov
join address a
on ov.supplier_id = a.id
where requested_date < getdate() and quote_flag = 'N'
order by requested_date desc


select distinct ship2_name
from p21_order_view
order by ship2_name

