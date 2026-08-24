/*
		01/24/2020 - created for sending emails to sales reps
		01/272020 - add approved = 'Y' to cteOH to eliminate quotes
		02/06/2020 - add branch
		02/24/2020 change BranchId to SalesSalesBranchID,ShipFromID, add ShipFromID
		08/10/2020 - add Addr per George's request
		08/11/2020 - add po_no, approved, order_date format mm/dd/yyyy need to modifiy for non approved orders (v2)
		10/02/2020 - yesterday if email fails
*/

use P21;

/*
if OBJECT_ID ('Daily_Yesterday_Orders_VW', 'V') is not null
drop view Daily_Yesterday_Orders_VW;
go

create view [dbo].[Daily_Yesterday_Orders_VW] AS
*/
With cteOH (order_date,po_no,order_no,Approved,customer_id,ship2_CompanyName,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState)
as
(
	select order_date,po_no,order_no,approved,h.customer_id,ship2_name,taker,h.location_id,source_location_id,ship_to_phone,(first_name + ' ' + last_name),ship2_add1,
	case when ship2_zip is null then 'ZZZZZ' else ship2_zip end,
	case when ship2_city is null then 'CCCCC' else ship2_city end,
	case when ship2_state is null then 'SSSSS' else ship2_state end
	from oe_hdr h
	join contacts c
	on h.contact_id = c.id
	where order_date Between dateadd(day,datediff(day,1,GETDATE()),0) and getdate() and  cancel_flag = 'N' and projected_order = 'N'
	
),
cteLegacy(order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState)
as
(
	select order_date,po_no,order_no,approved,cu.customer_id,legacy_id,ship2_CompanyName,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState
	from cteOH ch
	join customer cu
	on ch.customer_id = cu.customer_id 
),
cteSR(order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState)
as
(
	select order_date,po_no,order_no,approved,customer_id,case when legacy_id is null then ' ' else legacy_id end,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState
	from cteLegacy cl
	join oe_hdr_salesrep os
	on cl.order_no = os.order_number
),
cteOLinePrice(order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price)
as
(
	select order_date,po_no,sr.order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,
	cast(qty_ordered as int),cast(unit_price as decimal(10,2)),cast(extended_price as decimal(10,2))
	from cteSR sr
	join oe_line l
	on sr.order_no = l.order_no
),
cteItemDesc(order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price)
As
(
	select order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
	from cteOLinePrice cop
	join inv_mast i
	on cop.inv_mast_uid = i.inv_mast_uid
), 
cteAddSRName(order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,SalesRepName,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price)
as
(
	select order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,(first_name + ' ' + last_name + ' (' + salesrep_id +')'),taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
	from cteItemDesc cid
	join contacts c2
	on cid.salesrep_id =  c2.id
)
select order_no,convert(varchar(2),(datepart(MONTH,order_date)))+ '/' + convert(varchar(2),(datepart(day,order_date)))  + '/'+ convert(varchar(4),(datepart(YEAR,order_date)))[order_date],po_no,approved,customer_id,legacy_id,name[CompanyName],ship2_CompanyName,salesrep_id,SalesRepName,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
from cteAddSRName cSR
join address a
on cSR.customer_id = a.id
--where salesrep_id = 1006
--order by order_no
