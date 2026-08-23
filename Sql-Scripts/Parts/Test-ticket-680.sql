select m.class_id5,isu.supplier_id, s.supplier_name,loc_cost,u.pack_type,u.carton_size,u.carton_qty,pack_notes_1,pack_notes_2,pack_notes_3,pack_notes_4,pack_notes_5
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
join dbo.inventory_supplier_x_loc isxl
on isu.inventory_supplier_uid = isxl.inventory_supplier_uid
join dbo.supplier s
on isu.supplier_id = s.supplier_id
join dbo.inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid
where item_id = '2101099359' and location_id = 410 and primary_supplier = 'Y'

select Sum(l.qty_shipped)[Total_shipped],sum(l.extended_price)[Total_Amount]
from inv_mast m
join invoice_line l
on m.inv_mast_uid = l.inv_mast_uid
where m.item_id = '2101099359' and l.date_created between '2022-04-20' and '2023-04-20' and customer_id

select top 1 jpl.price,'54533'[customer_id],m.class_id5,unit_cost_display
from dbo.job_price_line jpl
join dbo.inv_mast m
on jpl.inv_mast_uid = m.inv_mast_uid
left join dbo.inventory_receipts_line irl
on m.inv_mast_uid = irl.inv_mast_uid 
where item_id = '2101052524' and job_price_hdr_uid in (12,22)
order by irl.date_created desc

select *
from dbo.job_price_line
where inv_mast_uid = 99653

select top 1 unit_cost_display,*
from inventory_receipts_line
where inv_mast_uid = 52638
order by date_created desc

select *
from inv_mast
where item_id = '2101052510'