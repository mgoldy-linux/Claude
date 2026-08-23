select distinct h.po_no[Solve PO No],h.location_id,vpi.item_id[Item ID],mu.legacy_item_id,l.qty_ordered[Qty Ordered],(l.qty_ordered - qty_received)[Qty Remaining],l.line_no[Line No],vendor_name[Vendor Name],
format(order_date,'yyyy-MM-dd')[Purchase Order Date],format(l.date_due,'yyyy-MM-dd')[Estimated Due Date],format(l.required_date,'yyyy-MM-dd')[EX-Factory Date]--,container_name,vessel_name
from dbo.po_hdr h
join dbo.po_line l 
on h.po_no = l.po_no
join dbo.vendor v
on h.vendor_id = v.vendor_id
join dbo.p21_view_supplier_purchasing_info vpi
on l.inv_mast_uid = vpi.inv_mast_uid
join dbo.inv_mast im
on im.inv_mast_uid = l.inv_mast_uid
left join dbo.p21_view_vessel_report vv
on l.po_line_uid = vv.po_line_uid
join dbo.inv_mast_ud mu
on im.inv_mast_uid = mu.inv_mast_uid
where (l.complete = 'N' and h.location_id != 200 and h.delete_flag = 'N' and container_qty_received is null ) and l.required_date < getdate()
order by [Solve PO No],[Line No]


