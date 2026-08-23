/*
	03/02/2020 protype for weekly quotes reports
	03/04/2020 - Doug H recommend only quotes opened in the last week
	03/20/2020 - change address to mailing address for Mexico
	07/08/2020 - add delete flag clear out invalid quotes from view
	0/22/2020 - change date format mm/DD/yyyy
*/
use P21;
/*
if OBJECT_ID ('d_MailAddr_Weekly_Quotes_VW', 'V') is not null
drop view d_MailAddr_Weekly_Quotes_VW;
go

create view [dbo].[d_MailAddr_Weekly_Quotes_VW] AS
*/
With cteOH (order_no,customer_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,QuoteDate,oe_hdr_uid)
as
(
	select order_no,h.customer_id,ship2_name,taker,h.location_id,ship_to_phone,(first_name + ' ' + last_name),h.order_date,h.oe_hdr_uid
	from oe_hdr h
	join contacts c
	on h.contact_id = c.id
	where order_date > DATEADD(day,-14,GetDate()) and projected_order = 'Y' and h.delete_flag = 'N'
),
cteLegacy(order_no,customer_id,legacy_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,QuoteDate,oe_hdr_uid)
as
(
	select order_no,cu.customer_id,legacy_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,QuoteDate,oe_hdr_uid
	from cteOH ch
	join customer cu
	on ch.customer_id = cu.customer_id 
),
cteSR(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,QuoteDate,oe_hdr_uid)
as
(
	select order_no,customer_id,case when legacy_id is null then ' ' else legacy_id end,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,QuoteDate,oe_hdr_uid
	from cteLegacy cl
	join oe_hdr_salesrep os
	on cl.order_no = os.order_number
),
cteOLinePrice(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid)
as
(
	select sr.order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,customer_part_number,inv_mast_uid,product_group_id,
	cast(qty_ordered as int),cast(unit_price as decimal(10,2)),cast(extended_price as decimal(10,2)),QuoteDate,sr.oe_hdr_uid
	from cteSR sr
	join oe_line l
	on sr.order_no = l.order_no
),
cteItemDesc(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid)
As
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid
	from cteOLinePrice cop
	join inv_mast i
	on cop.inv_mast_uid = i.inv_mast_uid
), 
cteAddSRName(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid)
as
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,(first_name + ' ' + last_name + ' (' + salesrep_id +')'),taker,BranchID,TelNo,CustName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid
	from cteItemDesc cid
	join contacts c2
	on cid.salesrep_id =  c2.id
),
getCompanyAddress(order_no,QuoteDate,customer_id,legacy_id,CompanyName,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,oe_hdr_uid,Zipcode,City,SState)
as
(
	select order_no,QuoteDate,customer_id,legacy_id,name,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,oe_hdr_uid,
	case when a.mail_postal_code is null then 'zzzzz' else a.mail_postal_code end,
	case when a.mail_city is null then 'ccccc' else a.mail_city end,
	case when a.mail_state is null then 'sssss' else a.mail_state end
	from cteAddSRName cSR
	join address a
	on cSR.customer_id = a.id
)
select order_no,convert(varchar(2),(datepart(MONTH,QuoteDate)))+ '/' + convert(varchar(2),(datepart(day,QuoteDate)))  + '/'+ convert(varchar(4),(datepart(YEAR,QuoteDate)))[Quote Date],
convert(varchar(2),(datepart(MONTH,qh.expiration_date)))+ '/' + convert(varchar(2),(datepart(day,qh.expiration_date)))  + '/'+ convert(varchar(4),(datepart(YEAR,qh.expiration_date)))[Expiration Date],
customer_id,legacy_id,CompanyName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,Zipcode,City,SState[State]
from getCompanyAddress gcn
left join quote_hdr qh
on gcn.oe_hdr_uid = qh.oe_hdr_uid
--where salesrep_id = 1030





