-- for Billy

select h.po_no,l.line_no,vendor_name,order_date,l.date_due[Expected Date],l.required_date,vpi.inv_mast_uid,vpi.item_id,product_group_id,qty_ordered,qty_received,received_date,average_lead_time
from po_hdr h
join po_line l 
on h.po_no = l.po_no
join vendor v
on h.vendor_id = v.vendor_id
join p21_view_supplier_purchasing_info vpi
on l.inv_mast_uid = vpi.inv_mast_uid
join inv_mast im
on im.inv_mast_uid = l.inv_mast_uid
where l.complete = 'N' and h.location_id = 200 and h.vendor_id = 15829
order by po_no,line_no

select h.po_no,l.line_no,vendor_name,order_date,l.date_due[Expected Date],l.required_date,vpi.inv_mast_uid,vpi.item_id,product_group_id,qty_ordered,qty_received,received_date,average_lead_time,po_line_uid
from po_hdr h
join po_line l 
on h.po_no = l.po_no
join vendor v
on h.vendor_id = v.vendor_id
join p21_view_supplier_purchasing_info vpi
on l.inv_mast_uid = vpi.inv_mast_uid
join inv_mast im
on im.inv_mast_uid = l.inv_mast_uid
where l.complete = 'N' and h.location_id = 200 and h.vendor_id = 15829
order by po_no,line_no


/*
	Criteria - Open, Purchase location 200,PO#,Part #,Order QTY,Qty received,Supplier,Po date,Required date
	04/08/2022 - Can we have qty received removed and add qty remaining?
	'Qty Remaining' is not retrieved from the database; no database information available.
	The value is derived as IF ( unit_quantity - cf_unit_qty_received - cf_unit_qty_in_vessel >= 0, unit_quantity - cf_unit_qty_received - cf_unit_qty_in_vessel, 0).
*/
-- if Billy approves need to automate sending on the 1st & 15th of the month
select distinct h.po_no,vpi.item_id,l.qty_ordered,(l.qty_ordered - qty_received)[qty_remaining],/*need to find qty remaining,*/l.line_no,vendor_name,order_date,l.date_due[Expected Date],l.required_date
from po_hdr h
join po_line l 
on h.po_no = l.po_no
join vendor v
on h.vendor_id = v.vendor_id
join p21_view_supplier_purchasing_info vpi
on l.inv_mast_uid = vpi.inv_mast_uid
join inv_mast im
on im.inv_mast_uid = l.inv_mast_uid
left join p21_view_vessel_report vv
on l.po_line_uid = vv.po_line_uid
where l.complete = 'N' and h.location_id = 200  and h.delete_flag = 'N' and container_qty_received is null
order by po_no,line_no




select *
from inv_loc_stock_status