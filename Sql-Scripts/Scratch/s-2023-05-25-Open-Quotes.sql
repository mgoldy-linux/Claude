With cteOH (order_no,customer_id,ship2_CompanyName,taker,BranchID,TelNo,CustName,ZipCode,City,SState,QuoteDate,oe_hdr_uid,email,expiration_date)
as
(
	select order_no,h.customer_id,ship2_name,taker,h.location_id,ship_to_phone,(first_name + ' ' + last_name),
	case when ship2_zip is null then 'No_Zip' else ship2_zip end,
	case when ship2_city is null then 'No_City' else ship2_city end,
	case when ship2_state is null then 'No_State' else ship2_state end,h.order_date,h.oe_hdr_uid,coalesce(c.email_address,a.email_address,'No_email_address'),expiration_date
	from dbo.oe_hdr h
	join dbo.contacts c
	on h.contact_id = c.id
	join dbo.address a
	on c.id = a.id 
	join dbo.quote_hdr q
	on h.oe_hdr_uid = q.oe_hdr_uid
	where q.expiration_date > = GETDATE() and projected_order = 'Y' and h.delete_flag = 'N' and h.completed = 'N' 
)
select order_no
from cteOH
where order_no = 1457505
except 
select quote_no
from d_Orders_2_Quotes_VW


select order_no
from oe_hdr 
where projected_order = 'Y' and delete_flag = 'N' and completed = 'N' and date_created > DATEADD(DAY,-730,GetDate())-- and order_no = 1457505
except 
select quote_no
from d_Orders_2_Quotes_VW