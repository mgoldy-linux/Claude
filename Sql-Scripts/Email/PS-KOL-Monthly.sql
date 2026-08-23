-- if part is missing it means it hasn't shipped last 365 days.

With getKOLs (KOL_UIDS,item_id)
as
(
		select inv_mast_uid,item_id
		from inv_mast m
		where (m.item_desc like 'KOL%' or m.inv_mast_uid in (40243,40244,40272,40273)) and delete_flag = 'N'
),
getUIDs (inv_mast_uid,item_id,qty_shipped,qty_on_hand,qty_on_PO,[Check])
as
(
		select KOL_UIDs,k.item_id,floor(ISNULL(sum(qty_shipped),0)),floor(ISNULL(l.qty_on_hand,0)),floor(ISNULL(order_quantity,0)),
	case
		when sum(qty_shipped) > (qty_on_hand + order_quantity) then 'Review'
		else ' '
	end
	from getKOLs k
	left join invoice_line il
	on k.KOL_UIDS = il.inv_mast_uid
	left join  invoice_hdr h
	on h.invoice_no = il.invoice_no --and invoice_date between dateadd(day,datediff(day,365,GetDate()),0) and getdate() 
	left join inv_loc l
	on k.KOL_UIDS =l.inv_mast_uid
	left join inv_loc_stock_status ilss
	on k.KOL_UIDS = ilss.inv_mast_uid
	where invoice_date between dateadd(day,datediff(day,365,GetDate()),0) and getdate() 
	group by k.KOL_UIDS,k.item_id,l.qty_on_hand,order_quantity
)
select legacy_item_id,legacy_item_description,item_id,qty_shipped,qty_on_hand,qty_on_PO,[Check],g.inv_mast_uid
from getUIDs g
left join inv_mast_ud mu
on g.inv_mast_uid = mu.inv_mast_uid
order by inv_mast_uid