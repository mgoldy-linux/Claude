with getKOLParts(item_id, inv_mast_uid,qty_on_hand,Qty_on_po)
as
(
	select im.item_id, im.inv_mast_uid,qty_on_hand,order_quantity[Qty on P.O.]
	from inv_mast im
	join inv_loc l
	on im.inv_mast_uid = l.inv_mast_uid
	where im.item_id like 'KOL%'
),
getSalesOrders(item_id, inv_mast_uid,qty_on_hand,Qty_on_po,qty_on_sales_order)
as
(
	select item_id, gdp.inv_mast_uid,qty_on_hand,Qty_on_po,ilss.qty_on_sales_order
	from getKOLParts gdp
	left join inv_loc_stock_status ilss
	on gdp.inv_mast_uid = ilss.inv_mast_uid
),-- Nov 2020
getInvoicesNoNov(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where year(invoice_date) = 2020 and MONTH(invoice_date) = 11
),
getQty_ShippedNov(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id like 'KOL%'
),
Nov2020(item_id,qty_shippedNov20)
as
(
	select item_id,Isnull(qty_shipped,0)
	from getInvoicesNoNov gi
	join getQty_ShippedNov gs
	on gi.invoice_no = gs.invoice_no
),
-- dec2020
getInvoicesNoDec(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where year(invoice_date) = 2020 and MONTH(invoice_date) = 12
),
getQty_ShippedDec(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id like 'KOL%'
),
Dec2020(item_id,qty_shippedDEC20)
as
(
	select item_id,Isnull(qty_shipped,0)
	from getInvoicesNoDec gi
	join getQty_ShippedDec gs
	on gi.invoice_no = gs.invoice_no
),
-- Jan 21
getInvoicesNoJan(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where year(invoice_date) = 2021 and MONTH(invoice_date) = 1
),
getQty_ShippedJan(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id like 'KOL%'
),
Jan2021(item_id,qty_shippedJan2021)
as
(
	select item_id,Isnull(qty_shipped,0)
	from getInvoicesNoJan gi
	join getQty_ShippedJan gs
	on gi.invoice_no = gs.invoice_no
),
-- feb 21
getInvoicesNoFeb(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where year(invoice_date) = 2021 and MONTH(invoice_date) = 2
),
getQty_ShippedFeb(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id like 'KOL%'
),
Feb2021(item_id,qty_shippedFeb2021)
as
(
	select item_id,Isnull(qty_shipped,0)
	from getInvoicesNoFeb gi
	join getQty_ShippedFeb gs
	on gi.invoice_no = gs.invoice_no
),
-- March 21
getInvoicesNoMar(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where year(invoice_date) = 2021 and MONTH(invoice_date) = 3
),
getQty_ShippedMar(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id like 'KOL%'
),
Mar2021(item_id,qty_shippedMar2021)
as
(
	select item_id,Isnull(qty_shipped,0)
	from getInvoicesNoMar gi
	join getQty_ShippedMar gs
	on gi.invoice_no = gs.invoice_no
),
-- Apr21
getInvoicesNoApr(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where year(invoice_date) = 2021 and MONTH(invoice_date) = 4
),
getQty_ShippedApr(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id like 'KOL%'
),
April2021(item_id,qty_shippedApr2021)
as
(
	select item_id,Isnull(qty_shipped,0)
	from getInvoicesNoApr gi
	join getQty_ShippedApr gs
	on gi.invoice_no = gs.invoice_no
),
-- May21
getInvoicesNoMay(invoice_no,shipped_date) 
as
(
	select invoice_no,invoice_date
	from invoice_hdr
	where year(invoice_date) = 2021 and MONTH(invoice_date) = 5
),
getQty_ShippedMay(item_id,qty_shipped,invoice_no)
as
(
	select il.item_id,floor(ISNULL(qty_shipped,0)),il.invoice_no --,il.inv_mast_uid
	from invoice_line il
	join inv_mast im
	on il.inv_mast_uid = im.inv_mast_uid
	where im.item_id like 'KOL%'
),
May2021(item_id,qty_shippedMay2021)
as
(
	select item_id,Isnull(qty_shipped,0)
	from getInvoicesNoMay gi
	join getQty_ShippedMay gs
	on gi.invoice_no = gs.invoice_no
),
SumNov(item_id,TotalNov20)
as
(
	select item_id,SUM(qty_shippedNov20)
	from Nov2020 
	group by item_id
),
SumDec(item_id,TotalDec20)
as
(
	select item_id,SUM(qty_shippedDec20)
	from Dec2020 
	group by item_id
),
SumJan(item_id,TotalJan21)
as
(
	select item_id,SUM(qty_shippedJan2021)
	from Jan2021
	group by item_id
),
SumFeb(item_id,TotalFeb21)
as
(
	select item_id,SUM(qty_shippedFeb2021)
	from Feb2021
	group by item_id
),
SumMar(item_id,TotalMar21)
as
(
	select item_id,SUM(qty_shippedMar2021)
	from Mar2021
	group by item_id
),
SumApr(item_id,TotalApr21)
as
(
	select item_id,SUM(qty_shippedApr2021)
	from April2021
	group by item_id
),
SumMay(item_id,TotalMay21)
as
(
	select item_id,SUM(qty_shippedMay2021)
	from May2021
	group by item_id
)
select gso.item_id[Item ID],qty_on_hand[Qty on Hand],Qty_on_po[Qty on P.O.],coalesce(qty_on_sales_order,0)[Qty on Sales Order],TotalNov20,TotalDec20,TotalJan21,TotalFeb21,TotalMar21,TotalApr21,TotalMay21
from getSalesOrders gso
left join SumNov n
on gso.item_id = n.item_id
left join SumDec d
on gso.item_id = d.item_id
left join SumJan j
on gso.item_id = j.item_id
left join SumFeb f
on gso.item_id = f.item_id
left join SumMar m
on gso.item_id = m.item_id
left join SumApr a
on gso.item_id = a.item_id
left join SumMay ma
on gso.item_id = ma.item_id
order by gso.item_id

/*
select a.item_id,SUM(qty_shippedMar2021)[TotalMar21],SUM(qty_shippedApr2021)[TotalApr21]
from April2021 a
join Mar2021 m
on a.item_id = m.item_id
group by a.item_id
*/

