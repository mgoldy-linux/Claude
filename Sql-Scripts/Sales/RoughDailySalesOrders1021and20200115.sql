Use P21;

With cteOH (order_no,customer_id,ship2_CompanyName,taker,TelNo,CustName,ZipCode,City,SState)
as
(
	select order_no,h.customer_id,ship2_name,taker,ship_to_phone,(first_name + ' ' + last_name),ship2_zip,ship2_city,ship2_state
	from oe_hdr h
	join contacts c
	on h.contact_id = c.id
	where Year(order_date) = 2020 and Month(order_date) = 1 and Day(order_date) = 15
),
cteLegacy(order_no,customer_id,legacy_id,ship2_CompanyName,taker,TelNo,CustName,ZipCode,City,SState)
as
(
	select order_no,cu.customer_id,legacy_id,ship2_CompanyName,taker,TelNo,CustName,ZipCode,City,SState
	from cteOH ch
	join customer cu
	on ch.customer_id = cu.customer_id 
),
cteSR(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState)
as
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState
	from cteLegacy cl
	join oe_hdr_salesrep os
	on cl.order_no = os.order_number
),
cteOLinePrice(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price)
as
(
	select sr.order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price
	from cteSR sr
	join oe_line l
	on sr.order_no = l.order_no
),
cteItemDesc(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price)
As
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
	from cteOLinePrice cop
	join inv_mast i
	on cop.inv_mast_uid = i.inv_mast_uid
)
select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,(first_name + ' ' + last_name + ' (' + salesrep_id +')')[SalesRepName],taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
from cteItemDesc cid
join contacts c2
on cid.salesrep_id =  c2.id
where salesrep_id = 1021
--order by SalesRepName