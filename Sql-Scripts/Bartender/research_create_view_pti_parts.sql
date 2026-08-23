-- use cte to filter out null, pick s-upc over m-upc
with getParts
as
(
	select distinct m.item_id,customer_part_number,m.item_desc,m.default_product_group,
	m.inv_mast_uid,m.upc_or_ean_id
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
join assembly_hdr a
on l.inv_mast_uid = a.inv_mast_uid
join inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
where h.delete_flag = 'N' and h.completed = 'N' and location_id = 100 and l.delete_flag = 'N' and l.complete = 'N'
),
getSupplierUPC
as
(
	select distinct item_id, customer_part_number, item_desc, default_product_group,isnull(upc_or_ean_id,s.upc_code)[UPC],ISNULL(s.upc_code,upc_or_ean_id)[S-UPC]
	from getParts gp
	join inventory_supplier s
	on gp.inv_mast_uid = s.inv_mast_uid
)
select item_id, customer_part_number, item_desc, default_product_group, UPC,[S-UPC],
case
	when [S-UPC] is null then customer_part_number
	when [S-UPC] = '' then UPC
	else [S-UPC]
end [Final-UPC]
from getSupplierUPC
order by default_product_group
