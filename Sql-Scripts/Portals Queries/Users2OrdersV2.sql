-- 2nd attempt for finding open orders for portal
-- in live need to make _oe_QTM a column qty_to_make a varchar so I display non-assembly as N/A?

with getTakers 
as
(
	select u.id,u.name,role,default_branch
	from roles r
	join users u
	on r.role_uid = u.role_uid
	where (r.role like '%inside%'  or r.role like '%EDI%') and r.delete_flag = 'N' and u.delete_flag = 'N'
	),
getOpenOrders(customer_id,order_no,order_date,ship2_name,requested_date,po_no,taker,line_no,item_id,qty_ordered,qty_canceled,qty_invoiced,qty_on_pick_tickets,qty_remaining,qty_to_make)
as
(
	select customer_id, h.order_no,replace(convert(varchar(12),order_date, 110),'-','/'),ship2_name,replace(convert(varchar(12),requested_date, 110),'-','/'),po_no,taker,line_no,im.item_id,convert(int,qty_ordered),convert(int,qty_canceled),convert(int,qty_invoiced),convert(int,qty_on_pick_tickets),convert(int,(qty_ordered - qty_allocated -qty_invoiced)),
	convert(varchar,qtm.QTM)
	from getTakers gt
	join oe_hdr h
	on gt.id = h.taker
	join oe_line ol
	on h.order_no = ol.order_no
	left join _oe_QTM qtm
	on ol.inv_mast_uid = qtm.assy_im_uid
	join inv_mast im
	on ol.inv_mast_uid = im.inv_mast_uid
	where approved = 'Y' and completed = 'N' and name = 'Ray Carter' and projected_order = 'N' and h.delete_flag = 'N' and h.cancel_flag = 'N' and ol.product_group_id != 'OTHERCHG' and ol.delete_flag = 'N'
)
select *
from getOpenOrders 