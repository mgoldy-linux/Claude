--use P21;

-- SST All Combine open on POs
select s.supplier_name,concat(h.po_no,'.',l.line_no)[Cont-PoNo-Line],pls.release_no,h.external_po_no,
case 
 when cbp.po_container_unit_qty is null then''
 else concat(replace(format(cbp.po_container_unit_qty,'N0'),',',''),'.',cbp.container_building_uid)
 end[Conc-Qty.Cont-ID],m.item_id,l.item_description,l.date_due,l.qty_ordered,(l.qty_ordered - l.qty_received)[cc_qty_open],l.unit_price,h.supplier_id,h.approved,pls.release_no,pls.release_date,' '[Acknowledge Date],l.qty_received,l.required_date[EX-Factory Date],l.expected_ship_date[Estimated EX-Port Date],branch_id
from dbo.po_hdr h
join dbo.po_line l 
on h.po_no = l.po_no
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join supplier s
on h.supplier_id = s.supplier_id
left join dbo.container_building_po cbp
on l.po_line_uid = cbp.po_line_uid
left join dbo.po_line_schedule pls
on l.po_line_uid = pls.po_line_uid
where l.complete = 'N' and branch_id in (510,520) and h.po_no = 4013303
order by [Cont-PoNo-Line]

/*
-- SST All open on POs
select s.supplier_name,h.po_no,l.line_no,pls.release_no,h.external_po_no,
case 
 when cbp.po_container_unit_qty is null then''
 else concat(replace(format(cbp.po_container_unit_qty,'N0'),',',''),'.',cbp.container_building_uid)
 end[Conc-Qty.Cont-ID],m.item_id,l.item_description,l.date_due,l.qty_ordered,(l.qty_ordered - l.qty_received)[cc_qty_open],l.unit_price,h.supplier_id,h.approved,pls.release_no,pls.release_date,' '[Acknowledge Date],l.qty_received,l.required_date[EX-Factory Date],l.expected_ship_date[Estimated EX-Port Date],branch_id
from dbo.po_hdr h
join dbo.po_line l 
on h.po_no = l.po_no
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join supplier s
on h.supplier_id = s.supplier_id
left join dbo.container_building_po cbp
on l.po_line_uid = cbp.po_line_uid
left join dbo.po_line_schedule pls
on l.po_line_uid = pls.po_line_uid
where l.complete = 'N' and branch_id in (510,520) and h.po_no = 4013303
order by po_no

select top 7 *
from po_line_schedule

-- SST open on containers
select h.po_no,l.line_no,m.item_id,l.item_description,l.date_due,l.qty_ordered,(l.qty_ordered - l.qty_received)[cc_qty_open],l.unit_price,h.supplier_id,s.supplier_name,h.external_po_no,cbp.po_container_unit_qty,cbp.container_building_uid
from dbo.po_hdr h
join dbo.po_line l 
on h.po_no = l.po_no
join dbo.inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
join supplier s
on h.supplier_id = s.supplier_id
join dbo.container_building_po cbp
on l.po_line_uid = cbp.po_line_uid
where l.complete = 'N' and branch_id in(510,520)
order by po_no


select top 4*
from dbo.po_line_schedule pls
where po_no

*/

select concat(po_no,'.', line_no)[t]
from po_line
where complete = 'N' and po_no = 4008370
order by t