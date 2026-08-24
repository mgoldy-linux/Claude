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
where l.complete = 'N' and h.location_id = 100 and h.vendor_id = 15966
order by po_no,line_no

/*
select vendor_id, vendor_name, legacy_id
from vendor
where vendor_id = 15966

select *
from po_line
where po_no = 4005850

select *
from item_lead_time
where po_no = 4005850

select *
from p21_view_supplier_purchasing_info
where location_id = 100 and inv_mast_uid = 49048

select *
from inv_mast
where item_id = 'SN510'
*/