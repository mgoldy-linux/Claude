-- 06/20/2022 - Maria said the query is good
-- format(v.date_created,'yyyy-MM-dd')[Create_Date]
-- used in Open-PO-NOT-on-Vessel-yyyyMMdd.xlsx

-- if Billy approves need to automate sending on the 1st & 15th of the month
-- add ext desc because new 
-- missing KOL-BEA-6004BA-001,KOL-BEA-6006BA-001, KOL-CP00107
/*
select distinct h.po_no[Solve PO No],vpi.item_id[Item ID],im.extended_desc,l.qty_ordered[Qty Ordered],(l.qty_ordered - qty_received)[Qty Remaining],l.line_no[Line No],vendor_name[Vendor Name],format(order_date,'yyyy-MM-dd')[Purchase Order Date],format(l.date_due,'yyyy-MM-dd')[Estimated Due Date],format(l.required_date,'yyyy-MM-dd')[EX-Factory Date]
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
order by [Solve PO No],[Line No]
*/
-- if Billy approves need to automate sending on the 1st & 15th of the month
-- add ext desc because new ,add date filter ont orders greater than today
-- Update dates to match PO entry screen
-- USE this one
select distinct h.po_no[Solve PO No],vpi.item_id[Item ID],mu.legacy_item_id,l.qty_ordered[Qty Ordered],(l.qty_ordered - qty_received)[Qty Remaining],l.line_no[Line No],vendor_name[Vendor Name],
format(order_date,'yyyy-MM-dd')[Purchase Order Date],format(l.date_due,'yyyy-MM-dd')[Estimated Due Date],format(l.required_date,'yyyy-MM-dd')[EX-Factory Date]
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
join inv_mast_ud mu
on im.inv_mast_uid = mu.inv_mast_uid
where (l.complete = 'N' and h.location_id = 200 and h.delete_flag = 'N' and container_qty_received is null or  vpi.inv_mast_uid in (467,40241,40270)) and l.required_date < getdate()
order by [Solve PO No],[Line No]

/*
select *
from inv_mast_ud
where legacy_item_id in ('KOL-CP00107','KOL-BEA-6006BA-001','KOL-BEA-6004BA-001')

select distinct h.po_no[Solve PO No],vpi.inv_mast_uid[inv_mast_uid],l.qty_ordered[Qty Ordered],(l.qty_ordered - qty_received)[Qty Remaining],l.line_no[Line No],vendor_name[Vendor Name],format(order_date,'yyyy-MM-dd')[Order Date],format(l.date_due,'yyyy-MM-dd')[Expected Date],format(l.required_date,'yyyy-MM-dd')[Required Date]
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
where (l.complete = 'N' and h.location_id = 200 and h.delete_flag = 'N' and container_qty_received is null or  vpi.inv_mast_uid in (467,40241,40270)) and l.date_due < getdate()
order by [Solve PO No],[Line No]
*/