/*
  01/14/2020 - create daily sales report for George
  Need  1st line (header) - Order #, Cust ID, Legacy ID, Customer Name(ship2_name), Sales rep,Inside Sales(taker), Customer Contact, Customer's tel. no. (Ship_to_phone)
		2nd line Item no. item description, pl, qty, unit price, ext amt $
		Final line if group Total for Order#, qty of parts, total of order

		oe_hdr_salesrep find salesrep_id
		contacts for customer contact
		01/24/2020 live verision add address name

	01/27/2020 add projected_order != 'Y' to filter out quotes

*/
use P21;

/*
if OBJECT_ID ('Daily_Orders_VW', 'V') is not null
drop view Daily_Orders_VW;
go

create view [dbo].[Daily_Orders_VW] AS
*/
With cteOH (order_no,customer_id,branch_id,ship2_CompanyName,taker,TelNo,CustName,ZipCode,City,SState)
as
(
	select order_no,h.customer_id,h.location_id,ship2_name,taker,ship_to_phone,(first_name + ' ' + last_name),
	case when ship2_zip is null then 'ZZZZZ' else ship2_zip end,
	case when ship2_city is null then 'CCCCC' else ship2_city end,
	case when ship2_state is null then 'SSSSS' else ship2_state end
	from oe_hdr h
	join contacts c
	on h.contact_id = c.id
	where Year(order_date) =  Year(GetDate())  and Month(order_date) = Month(GetDate()) and Day(order_date) = Day(GetDate()) and approved = 'Y'
),
cteLegacy(order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,taker,TelNo,CustName,ZipCode,City,SState)
as
(
	select order_no,cu.customer_id,branch_id,legacy_id,ship2_CompanyName,taker,TelNo,CustName,ZipCode,City,SState
	from cteOH ch
	join customer cu
	on ch.customer_id = cu.customer_id 
),
cteSR(order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState)
as
(
	select order_no,customer_id,branch_id,case when legacy_id is null then ' ' else legacy_id end,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState
	from cteLegacy cl
	join oe_hdr_salesrep os
	on cl.order_no = os.order_number
	where salesrep_id = 1021
),
cteOLinePrice(order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price)
as
(
	select sr.order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,
	cast(qty_ordered as int),cast(unit_price as decimal(10,2)),cast(extended_price as decimal(10,2))
	from cteSR sr
	join oe_line l
	on sr.order_no = l.order_no
),
cteItemDesc(order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price)
As
(
	select order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,salesrep_id,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
	from cteOLinePrice cop
	join inv_mast i
	on cop.inv_mast_uid = i.inv_mast_uid
), 
cteAddSRName(order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,salesrep_id,SalesRepName,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price)
as
(
	select order_no,customer_id,branch_id,legacy_id,ship2_CompanyName,salesrep_id,(first_name + ' ' + last_name + ' (' + salesrep_id +')'),taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
	from cteItemDesc cid
	join contacts c2
	on cid.salesrep_id =  c2.id
)
select order_no,customer_id,branch_id,legacy_id,name[CompanyName],ship2_CompanyName,salesrep_id,SalesRepName,taker,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
from cteAddSRName cSR
join address a
on cSR.customer_id = a.id
/*
select *
from oe_hdr
where order_no = 1028523

select *
from customer
where legacy_id = 'AIT2385'
*/


