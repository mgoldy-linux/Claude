/*
		01/24/2020 - created for sending emails to sales reps
		01/272020 - add approved = 'Y' to cteOH to eliminate quotes
		02/06/2020 - add branch
		02/24/2020 change BranchId to SalesSalesBranchID,ShipFromID, add ShipFromID
		08/10/2020 - add Addr per George's request
		08/11/2020 - add po_no, approved, order_date format mm/dd/yyyy need to modifiy for non approved orders (v2)
		10/27/2020 - add sales manager per email from GDib
		10/28/2020 - fixed null salesmanger
		02/22/2021 - change order date to "where order_date between DATEADD(day, -1, GETDATE()) and DATEADD(day, 1, GETDATE())" , add view permissions
		02/04/2022 - removed other charge from the view
		08/31/2022 - add os.delete_flag = 'N', reassign sales reps.
*/
--use P21Play;
use P21;

/*
if OBJECT_ID ('Daily_Orders_VW', 'V') is not null
drop view Daily_Orders_VW;
go

create view [dbo].[Daily_Orders_VW] AS
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
	/*where Year(order_date) =  Year(GetDate())  and Month(order_date) = Month(GetDate()) and Day(order_date) = Day(GetDate()) and approved = 'N'*/
	where order_date between DATEADD(day, -1, GETDATE()) and DATEADD(day, 1, GETDATE()) and cancel_flag = 'N' and projected_order = 'N'
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
	where os.delete_flag = 'N' --and os.primary_salesrep = 'Y' -- lose some records
),
cteOLinePrice(order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price)
as
(
	select order_date,po_no,sr.order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,
	cast(qty_ordered as int),cast(unit_price as decimal(10,2)),cast(extended_price as decimal(10,2))
	from cteSR sr
	join oe_line l
	on sr.order_no = l.order_no
	where product_group_id != 'OTHERCHG'
),
cteItemDesc(order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price)
As
(
	select order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
	from cteOLinePrice cop
	join inv_mast i
	on cop.inv_mast_uid = i.inv_mast_uid
), 
cteAddSRName(srm,order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,SalesRepName,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price)
as
(
	select case 
		when cid.salesrep_id  = 1005 then 'LMS House Account'
		when cid.salesrep_id  = 1006 then 'IPTCI HOUSE CORPORATE'
		when cid.salesrep_id in (1004,1028,1030,18353) then 'George Dib'
		when cid.salesrep_id in (1020,1022,1032,1023,10659,1033,1038,1039,1040,34446) then  'Ryan Linke'
		when cid.salesrep_id in (1017,1021,1025,1026,1029,1035,34445) then 'Scott Kuhn'
		else 'Unknown' end,
		order_date,po_no,order_no,approved,customer_id,legacy_id,ship2_CompanyName,salesrep_id,(first_name + ' ' + last_name + ' (' + salesrep_id +')'),taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
	from cteItemDesc cid
	join contacts c2
	on cid.salesrep_id =  c2.id
)
select srm[SalesManager],order_no,convert(varchar(2),(datepart(MONTH,order_date)))+ '/' + convert(varchar(2),(datepart(day,order_date)))  + '/'+ convert(varchar(4),(datepart(YEAR,order_date)))[order_date],po_no,approved,customer_id,legacy_id,name[CompanyName],ship2_CompanyName,salesrep_id,SalesRepName,taker,SalesBranchID,ShipFromID,TelNo,CustName,Addr,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price
from cteAddSRName cSR
join address a
on cSR.customer_id = a.id
--where salesrep_id = 1017
--where order_no = 1316163
--order by order_no


go

/*
grant select on object::Daily_Orders_VW to p21_application_role
grant select on object::Daily_Orders_VW to PxxiUser
grant select on object::Daily_Orders_VW to [PTIDOM\P21Users]
*/