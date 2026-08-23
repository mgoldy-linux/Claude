/*
select distinct sv.order_no,customer_part_number,sv.item_desc,sv.item_id,im.upc_or_ean_id,im.short_code,po_no,sv.source_code_no
from p21_sales_history_report_view sv
join inv_mast im
on sv.inv_mast_uid = im.inv_mast_uid
where order_date > '09/30/2019'  and customer_name like 'Motion%' --and ship_loc_id = 100
order by short_code

select customer_part_number,l.order_no,h.order_date,source_loc_id,h.customer_id,h.ship2_add1,h.ship2_city,po_no
from oe_line l
join oe_hdr h
on l.order_no = h.order_no
where l.date_created between '2019-11-26' and '2019-11-28' and h.ship2_city = 'Russellville' and source_loc_id = 300

select * from oe_line where order_no = 1017397

select * from inv_mast where inv_mast_uid = 35231

select item_id, item_desc,short_code,extended_desc,upc_code,inv_mast_uid 
from p21_item_view
where class_id1 != 'LMS'
*/

-- missing UPC
with getMPN(order_no,customer_part_number,item_desc,item_id,short_code,po_no,inv_mast_uid,extended_desc)
as
(
	select sv.order_no,customer_part_number,sv.item_desc,sv.item_id,im.short_code,po_no,sv.inv_mast_uid,extended_desc
	from p21_sales_history_report_view sv
	join inv_mast im
	on sv.inv_mast_uid = im.inv_mast_uid
	where order_date > '09/30/2019'  and customer_name like 'Motion%'-- and upc_or_ean_id is null --and ship_loc_id = 100 
)
select distinct ' '[SKU], upc_code,item_desc,item_id
from getMPN gm
join inventory_supplier s
on gm.inv_mast_uid = s.inv_mast_uid
where short_code like 'UC 207 22%'
order by item_id


