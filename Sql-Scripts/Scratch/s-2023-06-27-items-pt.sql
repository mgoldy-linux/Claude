Select default_product_group,*
from inv_mast
where item_id = '2101020810'

select *
from oe_pick_ticket_detail
where inv_mast_uid = 26146

select *
from oe_pick_ticket 
where pick_ticket_no = 2390012


select pth.pick_ticket_no,item_id[SIMG],item_desc,extended_desc[ext_item_desc],default_product_group,
case
		when upc_or_ean_id is null and upc_code is not null then concat(upc_code , check_digit)
		 when upc_or_ean_id is not null and upc_code is null then upc_or_ean_id 
		 when upc_or_ean_id is not null and upc_code is not null then concat(upc_code , check_digit)
		 when upc_or_ean_id is null and upc_code is null then ''
end[UPC],country_of_origin
from dbo.oe_hdr h
join dbo.oe_pick_ticket pth
on h.order_no = pth.order_no
join dbo.oe_pick_ticket_detail d
on pth.pick_ticket_no = d.pick_ticket_no
join dbo.inv_mast m
on d.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where customer_id = 13443 and h.completed = 'N' and pth.delete_flag = 'N' and h.delete_flag = 'N' and pth.delete_flag = 'N'

Select *
from Bar_Item_ID_PTI_Labels_VW

select customer_name,*
from customer
where customer_name like '%Timken%'