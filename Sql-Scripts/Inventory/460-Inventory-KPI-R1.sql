with getinv_mast_uids(uid460,customer_name,qty_sold,last_invoice_date,invoice_price,customer_part_number)
as
(
select il.inv_mast_uid,customer_name,sum(il.qty_shipped)[Qty_Invoiced],max(format(ih.invoice_date,'yyyy-MM-dd'))[last-InvDate],il.unit_price,il.customer_part_number
from dbo.invoice_line il
join dbo.invoice_hdr ih
on il.invoice_no = ih.invoice_no
join customer c
on ih.customer_id = c.customer_id
where invoice_date between '2022-07-18' and getdate() and sales_location_id = 460 and product_group_id != 'OTHERCHG' and product_group_id is not null 
group by il.inv_mast_uid,customer_name,il.unit_price,customer_part_number 
),
getSalesOrders(item_desc,SIMG,customer_name,qty_shipped,invoice_date,inv_mast_uid,qty_on_hand,qty_allocated,qty_Available,qty_on_po,qty_on_sales_order,invoice_price,customer_part_number)
as
(
	select item_desc,item_id,customer_name,qty_sold,last_invoice_date,g.uid460,sum(qty_on_hand),sum(qty_allocated),sum((qty_on_hand - qty_allocated)),sum(order_quantity),sum(ilss.qty_on_sales_order),invoice_price,customer_part_number
	from getinv_mast_uids g
	join dbo.inv_mast m
	on g.uid460 = m.inv_mast_uid
	join dbo.inv_loc il
	on g.uid460 = il.inv_mast_uid
	join inv_loc_stock_status ilss
	on g.uid460= ilss.inv_mast_uid and il.location_id = ilss.location_id
	group by item_desc,item_id,g.uid460,customer_name,qty_sold,last_invoice_date,invoice_price,customer_part_number
),
getVesselNumbers(Vinv_mast_uid,vessel_location_id,qty_on_vessel)
as
(
	select inv_mast_uid,location_id,sum(v.container_qty_received)
	from dbo.po_line p
	join dbo.vessel_receipts_line v
	on p.po_line_uid = v.po_line_uid
	join dbo.po_hdr ph
	on p.po_no = ph.po_no
	where qty_received = 0 and  p.complete = 'N'
	group by inv_mast_uid,location_id
)
select item_desc,SIMG,invoice_price,customer_part_number,customer_name,qty_shipped,invoice_date,qty_on_hand,qty_allocated,qty_Available,coalesce((Qty_on_po - Qty_on_vessel),0)[qty_on_PO],coalesce(vessel_location_id,0)[vessel_location_id],coalesce(qty_on_vessel,0)[vessel_on_qty],qty_on_sales_order
from getSalesOrders gso
left join getVesselNumbers gvn
on gso.inv_mast_uid = gvn.Vinv_mast_uid
order by simg
