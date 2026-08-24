select *
from inventory_supplier
where inv_mast_uid = 52028

select item_id,default_product_group,product_group_id,im.date_created,l.date_created
from inv_mast im
join inv_loc l
on im.inv_mast_uid = l.inv_mast_uid
where default_product_group is null
order by product_group_id

select item_id,default_product_group,product_group_id,im.date_created,l.date_created
from inv_mast im
join inv_loc l
on im.inv_mast_uid = l.inv_mast_uid
where product_group_id is null
order by default_product_group

select *
from inv_loc
where inv_mast_uid = 52028

select *
from inv_xref
where inv_mast_uid = 52028


select distinct m.item_id,customer_part_number,m.item_desc,m.default_product_group,
	m.inv_mast_uid,m.upc_or_ean_id
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join assembly_hdr a
on l.inv_mast_uid = a.inv_mast_uid
join inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
where h.delete_flag = 'N' and h.completed = 'N' and location_id = 100 and l.delete_flag = 'N' and l.complete = 'N' and h.order_no = 1215030


-- reliamark
select item_id,default_product_group,product_group_id,im.date_created,l.date_created
from inv_mast im
join inv_loc l
on im.inv_mast_uid = l.inv_mast_uid
where default_product_group like 'K%'
order by product_group_id

-- NSK
select item_id,default_product_group,product_group_id,im.date_created,l.date_created
from inv_mast im
join inv_loc l
on im.inv_mast_uid = l.inv_mast_uid
where default_product_group = 'N1'
order by product_group_id


select item_id, class_id5
from inv_mast
where class_id1 = 'PTI' and class_id2 = 'EPL'-- and class_id3 is not null



select inv_mast_uid, item_id, item_desc, upc_or_ean_id, short_code,default_product_group
from inv_mast
where item_id = 'N-SUCSF205-25MM'

select *
from Bar_Item_ID_PTI_Labels_VW
where default_product_group = 'N1'
