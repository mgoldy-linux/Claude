
with getIBTCustomers(IBT_Branch_Name,customer_id)
as
(
	select a.name[IBT_Branch_Name],customer_id
	from customer c	
	join address a
	on c.customer_id = a.id
	where c.class_3id = 'IBT' 
),
getIBTInvoices(IBT_Branch_Name,customer_id,order_no)
as
(
	select IBT_Branch_Name,gi.customer_id,h.invoice_no
	from getIBTCustomers gi
	join invoice_hdr h
	on gi.customer_id = h.customer_id
),
getPNs(inv_mast_uid,item_id)
as
(
	select Distinct l.inv_mast_uid,l.item_id
	from getIBTInvoices giv
	join invoice_line l
	on giv.order_no = l.invoice_no
	where inv_mast_uid is not null and item_id not in ('REWORK-PTI','MISC-CUSTOMER-IPTCI','SPECIAL','MISC','RESTOCK-IPTCI','RESTOCK','SPECIAL-PTI','FREIGHTOUT','FREIGHTOUT-IPTCI','FEDEX','FRTINTL','CATALOG')
)
select gp.inv_mast_uid,gp.item_id,im.item_desc,im.upc_or_ean_id
from getPNs gp
join inv_mast im
on gp.inv_mast_uid = im.inv_mast_uid
where im.class_id2 = 'EPL'
/*
--where upc_or_ean_id is not null
where im.inv_mast_uid = 6527
--where im.upc_or_ean_id = 88388000681
order by item_desc


select l.inv_mast_uid
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where po_no = '32-V02779'

select *
from oe_hdr
where po_no = '01-R27220'
*/