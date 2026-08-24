/*		 
	02/04/2020 Create dodge inventory report - from Darin's Email
	Item ID             Qty on Hand       Qty Allocated     Qty Available      Qty on P.O.         Qty in Vessel           Qty on Sales Order
	D-141001X           4537              550               3987               25                   0						0
	06/09/2021 - add item description, Unit SO Price,Unit PO Price,qty non-pickable, last saledate Unit Price' is oe_line.unit_price 'PO Unit Price' is po_line.unit_price_display.
	06/09/2021 - remove qty avaliable & qty allocated
	06/09/2021 - remove duplicates by summing vessel qty
	07/21/2022 - new itemid
*/

Use P21;

--Get Dodge parts

with getDodgeParts(item_id,Description,inv_mast_uid,qty_on_hand,qty_allocated,Qty_Available,Qty_on_po)
as
(
	select im.item_id,item_desc, im.inv_mast_uid,qty_on_hand,qty_allocated,(qty_on_hand - qty_allocated)[Qty Available],order_quantity[Qty on P.O.]
	from inv_mast im
	join inv_loc l
	on im.inv_mast_uid = l.inv_mast_uid
	where im.item_desc between 'D-000000' and 'D-999999'
),
getSalesOrders(item_id,Description,inv_mast_uid,qty_on_hand,qty_allocated,Qty_Available,Qty_on_po,qty_on_sales_order,qty_non_pickable)
as
(
	select item_id,Description,gdp.inv_mast_uid,qty_on_hand,qty_allocated,Qty_Available,Qty_on_po,ilss.qty_on_sales_order,ilss.qty_non_pickable
	from getDodgeParts gdp
	left join inv_loc_stock_status ilss
	on gdp.inv_mast_uid = ilss.inv_mast_uid
),
getVesselNumbers(inv_mast_uid,Qty_on_vessel)
as
(
	select inv_mast_uid,sum(v.container_qty_received)
	from po_line p
	join vessel_receipts_line v
	on p.po_line_uid = v.po_line_uid
	where qty_received = 0 and  p.complete = 'N'
	group by inv_mast_uid
),
getlastsale(inv_mast_uid,last_sale_date)
as
(
	select m.inv_mast_uid,max(l.date_last_modified)
	from inv_mast m
	join invoice_line l
	on m.inv_mast_uid = l.inv_mast_uid
	where m.item_desc between 'D-000000' and 'D-999999'
	group by m.inv_mast_uid
),
getShippedF2019(inv_mast_uid,qty_shipped20190101)
as
(
	select im.inv_mast_uid,sum(floor(ISNULL(qty_shipped,0)))
	from inv_mast im
	left join invoice_line il
	on im.inv_mast_uid = il.inv_mast_uid and il.date_created > '2019-01-01'
	where im.item_desc between 'D-000000' and 'D-99999'
	group by im.inv_mast_uid
),
getShippedF2020Jan(inv_mast_uid,qty_shipped2020Jan)
as
(
	select im.inv_mast_uid,sum(floor(ISNULL(qty_shipped,0)))
	from inv_mast im
	left join invoice_line il
	on im.inv_mast_uid = il.inv_mast_uid and il.date_created > '2020-01-01'
	where im.item_desc between 'D-000000' and 'D-99999'
	group by im.inv_mast_uid
),
getShippedF2020Oct(inv_mast_uid,qty_shipped2020Oct)
as
(
	select im.inv_mast_uid,sum(floor(ISNULL(qty_shipped,0)))
	from inv_mast im
	left join invoice_line il
	on im.inv_mast_uid = il.inv_mast_uid and il.date_created > '2020-10-01'
	where im.item_desc between 'D-000000' and 'D-99999'
	group by im.inv_mast_uid
)
select gso.item_id[Item ID],Description, avg(l.unit_price)[SO Price], avg(p.unit_price)[PO Price],qty_on_hand[Qty on Hand],coalesce(qty_on_sales_order,0)[Qty on Sales Order],qty_non_pickable[Qty Non-Pickable],Qty_on_po[Qty on P.O.],coalesce(Qty_on_vessel,0)[Qty in Vessel],nt.qty_shipped20190101[Shipped 01/01/2019],j20.qty_shipped2020Jan[Shipped 01/01/2020],o20.qty_shipped2020Oct[Shipped 10/01/2020],replace(convert(varchar(12),last_sale_date,110),'-','/') as [Last Sale Date]
from getSalesOrders gso
left join  getVesselNumbers vn
on gso.inv_mast_uid = vn.inv_mast_uid
left join getlastsale ls
on gso.inv_mast_uid = ls.inv_mast_uid
join getShippedF2019 nt
on gso.inv_mast_uid = nt.inv_mast_uid
join getShippedF2020Jan j20
on gso.inv_mast_uid = j20.inv_mast_uid
join getShippedF2020Oct o20
on gso.inv_mast_uid = o20.inv_mast_uid
left join oe_line l
on gso.inv_mast_uid = l.inv_mast_uid
left join po_line p
on gso.inv_mast_uid = p.inv_mast_uid
group by gso.item_id,Description, qty_on_hand,qty_on_sales_order,qty_non_pickable,Qty_on_po,Qty_on_vessel,nt.qty_shipped20190101,j20.qty_shipped2020Jan,o20.qty_shipped2020Oct,last_sale_date
order by item_id