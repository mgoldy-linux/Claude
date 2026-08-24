select order_no,h.customer_id,po_no,location_id,carrier_id,address_id,c.customer_name
from oe_hdr h
join customer c
on h.customer_id = c.customer_id
where po_no like '24-%' and location_id = 300
order by po_no

select customer_name, c.customer_id,po_no
from customer c
join oe_hdr h
on c.customer_id = h.customer_id
where customer_name like 'IBT%' and default_branch_id = 300 and h.projected_order = 'N' and h.delete_flag = 'N'


select inv_mast_uid,supplier_part_no,upc_code,upc_code_source_type_cd
from inventory_supplier
where upc_code = '88803004145'

select im.inv_mast_uid,item_id,item_desc,upc_or_ean,upc_or_ean_id,short_code,item_type_cd,supplier_part_no,upc_code,upc_code_source_type_cd
from inv_mast im
join inventory_supplier ivs
on im.inv_mast_uid = ivs.inv_mast_uid
where short_code LIKE 'sucsOFB 204 12%' and class_id2 = 'EPL'

with getOrders(order_no,po_no,inv_mast_uid,customer_part_number)
as
(
	select h.order_no,po_no,inv_mast_uid,customer_part_number
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	where customer_id = 11556 and approved = 'Y'
)
select order_no,po_no,gor.inv_mast_uid,customer_part_number,short_code,upc_or_ean,item_id
from getOrders gor
join inv_mast im
on gor.inv_mast_uid = im.inv_mast_uid

with getOrders(order_no,po_no,inv_mast_uid,customer_part_number)
as
(
	select h.order_no,po_no,inv_mast_uid,customer_part_number
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	where customer_id = 15772 and approved = 'Y'
)
select order_no,po_no,gor.inv_mast_uid,customer_part_number,upc_code
from getOrders gor
join inventory_supplier isp
on gor.inv_mast_uid = isp.inv_mast_uid