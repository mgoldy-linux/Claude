
with getIBTCustomers(IBT_Branch_Name,customer_id)
as
(
	select a.name[IBT_Branch_Name],customer_id
	from customer c	
	join address a
	on c.customer_id = a.id
	where c.class_3id = 'IBT' 
),
getIBTInvoices(IBT_Branch_Name,customer_id,invoice_no)
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
	on giv.invoice_no = l.invoice_no
	where inv_mast_uid is not null and item_id not in ('REWORK-PTI','MISC-CUSTOMER-IPTCI','SPECIAL','MISC','RESTOCK-IPTCI','RESTOCK','SPECIAL-PTI','FREIGHTOUT','FREIGHTOUT-IPTCI','FEDEX','FRTINTL','CATALOG')
)
select gp.inv_mast_uid,gp.item_id,iv.item_desc,iv.upc_code
from getPNs gp
join p21_item_view iv
on gp.inv_mast_uid = iv.inv_mast_uid
where class_id2 = 'EPL'
--where upc_code = '88388000681'
--order by item_desc
/*
select *
from inventory_supplier
where upc_code = '88388000681'
where inv_mast_uid = 30403

select *
from inv_mast im
join inventory_supplier ins
on im.inv_mast_uid = ins.inv_mast_uid
where im.inv_mast_uid = 30403
*/