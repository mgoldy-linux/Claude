/*
	03/02/2020 protype for weekly quotes reports
	03/04/2020 - Doug H recommend only quotes opened in the last week
	07/08/2020 - removed deleted quotes
	08/21/2020 - change date format to mm/DD/yyyy
	01/26/2021 - change to 90 days per email from George
	06/07/2021 - add email addresses per email from George
	03/01/2022 - add h.completed to eliminate  quotes converted to orders
	05/24/2023 - REMOVE expire quotes
*/
--use P21;
use P21Play;
/*
if OBJECT_ID ('dWeekly_Quotes_VW', 'V') is not null
drop view dWeekly_Quotes_VW;
go

create view [dbo].[dWeekly_Quotes_VW] AS
*/
With getQuotes (order_no)  -- this removes quotes converted to orders
as
(
select order_no
from oe_hdr 
where projected_order = 'Y' and delete_flag = 'N' and completed = 'N' and date_created > DATEADD(DAY,-730,GetDate())
except 
select quote_no
from d_Orders_2_Quotes_VW
),
cteOH (order_no,customer_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid,email,expiration_date)
as
(
	select h.order_no,h.customer_id,ship2_name,taker,h.location_id,ship_to_phone,(first_name + ' ' + last_name),
	case when ship2_zip is null then 'No_Zip' else ship2_zip end,
	case when ship2_city is null then 'No_City' else ship2_city end,
	case when ship2_state is null then 'No_State' else ship2_state end,h.order_date,h.oe_hdr_uid,coalesce(c.email_address,a.email_address,'No_email_address'),expiration_date
	from getQuotes gq
	join dbo.oe_hdr h
	on gq.order_no = h.order_no
	join dbo.contacts c
	on h.contact_id = c.id
	join dbo.address a
	on c.id = a.id 
	join dbo.quote_hdr q
	on h.oe_hdr_uid = q.oe_hdr_uid
	where q.expiration_date > = GETDATE() and projected_order = 'Y' and h.delete_flag = 'N' and h.completed = 'N' 
),
cteLegacy(order_no,customer_id,legacy_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid,email,expiration_date)
as
(
	select order_no,cu.customer_id,legacy_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid,email,expiration_date
	from cteOH ch
	join customer cu
	on ch.customer_id = cu.customer_id 
),
cteSR(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid,email,expiration_date)
as
(
	select order_no,customer_id,case when legacy_id is null then ' ' else legacy_id end,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid,email,expiration_date
	from cteLegacy cl
	join oe_hdr_salesrep os
	on cl.order_no = os.order_number
),
cteOLinePrice(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid,email,expiration_date)
as
(
	select sr.order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,inv_mast_uid,product_group_id,
	cast(qty_ordered as int),cast(unit_price as decimal(10,2)),cast(extended_price as decimal(10,2)),QuoteDate,sr.oe_hdr_uid,email,expiration_date
	from cteSR sr
	join oe_line l
	on sr.order_no = l.order_no
),
cteItemDesc(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid,email,expiration_date)
As
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid,email,expiration_date
	from cteOLinePrice cop
	join inv_mast i
	on cop.inv_mast_uid = i.inv_mast_uid
), 
cteAddSRName(order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid,email,expiration_date)
as
(
	select order_no,customer_id,legacy_id,ship2_CompanyName,salesrep_id,(first_name + ' ' + last_name + ' (' + salesrep_id +')'),taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,QuoteDate,oe_hdr_uid,email,expiration_date
	from cteItemDesc cid
	join contacts c2
	on cid.salesrep_id =  c2.id
),
getCompanyName(order_no,QuoteDate,customer_id,legacy_id,CompanyName,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,oe_hdr_uid,email,expiration_date)
as
(
	select order_no,QuoteDate,customer_id,legacy_id,name,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,oe_hdr_uid,email,expiration_date
	from cteAddSRName cSR
	join address a
	on cSR.customer_id = a.id
)
select order_no,convert(varchar(2),(datepart(MONTH,QuoteDate)))+ '/' + convert(varchar(2),(datepart(day,QuoteDate)))  + '/'+ convert(varchar(4),(datepart(YEAR,QuoteDate)))[Quote Date],convert(varchar(2),(datepart(MONTH,expiration_date)))+ '/' + convert(varchar(2),(datepart(day,expiration_date)))  + '/'+ convert(varchar(4),(datepart(YEAR,expiration_date)))[Expiration Date],customer_id,legacy_id,CompanyName,customer_part_number,item_desc,product_group_id,qty_ordered,unit_price,extended_price,ship2_CompanyName,salesrep_id,SalesRepName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,email
from getCompanyName gcn
/*
go 

grant select on object::dWeekly_Quotes_VW to p21_application_role
grant select on object::dWeekly_Quotes_VW to PxxiUser
grant select on object::dWeekly_Quotes_VW to [PTIDOM\P21Users]
*/

