select top  72 *
from  vessel_receipts_line
where vessel_receipts_hdr_uid = 1504 and po_line_uid = 85067

select pl.item_description,pl.po_no,pl.po_line_uid,pl.unit_quantity,pl.line_no,pl.unit_price,pl.source_type,pl.line_type,expected_ship_date,isu.inv_mast_uid,vsl.*
from inventory_supplier isu
join po_line pl
on isu.inv_mast_uid = pl.inv_mast_uid
right join vessel_receipts_line vsl
on pl.po_line_uid = vsl.po_line_uid
where supplier_id = 46865 and pl.delete_flag = 'N'  and pl.cancel_flag = 'N' and pl.complete = 'N'

select *
from po_line
where po_line_uid = 85062

-- for larry A - ticket # 926
select distinct h.po_no,l.line_no,vpi.item_id, l.unit_price[cost],(l.unit_price * .9)[new_cost],l.po_line_uid
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
where l.complete = 'N' and h.location_id = 410  and h.delete_flag = 'N' and vpi.supplier_id = 46865 and container_qty_received is null
order by po_no,line_no

use P21Play;
update po_line
set unit_price_display = '0.351' 
where po_line_uid = 67341