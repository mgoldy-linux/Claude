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
--left join p21_view_vessel_report vv
--on l.po_line_uid = vv.po_line_uid
where l.complete = 'N' and h.location_id = 200  and h.delete_flag = 'N' and im.item_id = '6205-2RSX1-A1C0SRI2'

select *
from p21_view_vessel_report
where item_id = '6205-2RSX1-A1C0SRI2'

select top 5 *
from inv_loc_stock_status
where location_id = 200