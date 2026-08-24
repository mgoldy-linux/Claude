select distinct h.po_no,vpi.item_id,format(l.qty_ordered,'N0')[qty_ordered],format((l.qty_ordered - qty_received),'N0')[qty_remaining],l.line_no,vendor_name,
format(order_date,'MM/dd/yyyy')[order_date],format(l.date_due,'MM/dd/yyyy')[expected_date],format(l.required_date,'MM/dd/yyyy')[required_date]
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
where l.complete = 'N' and h.location_id = 410  and h.delete_flag = 'N' /*and im.item_id = '6205-2RSX1-A1C0SRI2'*/ and container_qty_received is null
order by po_no,line_no



select format(l.qty_ordered,'N0')[qty_ordered],format((l.qty_ordered - qty_received),'N0')[qty_remaining],container_qty_received,qty_received
from p21_view_po_line l
left join p21_view_vessel_report vv
on l.po_line_uid = vv.po_line_uid 
where l.po_no = 4005833 and container_qty_received is null


select *
from p21_view_vessel_report 
where po_no = 4005833

select *
from p21_view_po_line
where po_no = 4005833