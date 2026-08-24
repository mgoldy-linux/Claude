
with getIBT
as
(
	select c.customer_id, order_no
	from customer c
	join oe_hdr h
	on c.customer_id = h.customer_id
	where c.class_3id = 'IBT'
)
select count(distinct ol.customer_part_number)[timesOrder],ol.inv_mast_uid
from getIBT gi
join oe_line ol
on gi.order_no = ol.order_no
group by ol.inv_mast_uid
order by timesOrder desc