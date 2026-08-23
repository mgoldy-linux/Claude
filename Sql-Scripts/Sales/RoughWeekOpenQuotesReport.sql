/*
	03/02/2020 protype for weekly quotes reports
	03/04/2020 - Doug H recommend only quotes opened in the last week
*/
use P21Play;
/*
if OBJECT_ID ('dWeekly_Quotes_VW', 'V') is not null
drop view dWeekly_Quotes_VW;
go

create view [dbo].[dWeekly_Quotes_VW] AS
*/
With cteOH (order_no,customer_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid)
as
(
	select order_no,h.customer_id,ship2_name,taker,h.location_id,ship_to_phone,(first_name + ' ' + last_name),
	case when ship2_zip is null then 'ZZZZZ' else ship2_zip end,
	case when ship2_city is null then 'CCCCC' else ship2_city end,
	case when ship2_state is null then 'SSSSS' else ship2_state end,h.order_date,h.oe_hdr_uid
	from oe_hdr h
	join contacts c
	on h.contact_id = c.id
	where order_date > DATEADD(day,-14,GetDate()) and projected_order = 'Y'
),
cteLegacy(order_no,customer_id,legacy_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid)
as
(
	select order_no,cu.customer_id,legacy_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid
	from cteOH ch
	join customer cu
	on ch.customer_id = cu.customer_id 
),
cteSR(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid)
as
(
	select order_no,customer_id,case when legacy_id is null then ' ' else legacy_id end,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid
	from cteLegacy cl
	join oe_hdr_salesrep os
	on cl.order_no = os.order_number
),
cteOLinePrice(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid)
as
(
	select sr.order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,
	cast(qty_ordered as int),cast(unit_price as decimal(10,2)),cast(extended_price as decimal(10,2)),QuoteDate,sr.oe_hdr_uid
	from cteSR sr
	join oe_line l
	on sr.order_no = l.order_no
),
cteItemDesc(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid)
As
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid
	from cteOLinePrice cop
	join inv_mast i
	on cop.inv_mast_uid = i.inv_mast_uid
), 
cteAddSRName(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid)
as
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,(first_name + ' ' + last_name + ' (' + salesrep_id +')'),taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid
	from cteItemDesc cid
	join contacts c2
	on cid.salesrep_id =  c2.id
),
getCompanyName(order_no,QuoteDate,customer_id,legacy_id,CompanyName,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,oe_hdr_uid)
as
(
	select order_no,QuoteDate,customer_id,legacy_id,name,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,oe_hdr_uid
	from cteAddSRName cSR
	join address a
	on cSR.customer_id = a.id
)
select order_no,Convert(date,QuoteDate)[Quote Date],Convert(date,qh.expiration_date)[Expiration Date],customer_id,legacy_id,CompanyName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState
from getCompanyName gcn
left join quote_hdr qh
on gcn.oe_hdr_uid = qh.oe_hdr_uid
--where gcn.salesrep_id = 1024
--order by QuoteDate desc



