-- find agco orders

with getOrders(cid,cname,ono)
as
(
	select c.customer_id, customer_name,h.order_no
	from customer c
	join oe_hdr h
	on c.customer_id = h.customer_id
	where customer_name like 'Agco%' and order_date > '2020-04-01'
),
getOrderLine(cname,ono,customer_part_number,inv_mast_uid)
as
(
	select cname,ono,l.customer_part_number,inv_mast_uid
	from getOrders gor
	join oe_line l
	on gor.ono = l.order_no
)
select cname,ono,customer_part_number,im.item_id,im.upc_or_ean_id
from getOrderLine gol
join inv_mast im
on gol.inv_mast_uid = im.inv_mast_uid