/*		 
	11/09/2020 Create Meyn inventory report - from George's Email
	Item ID             Qty on Hand       Qty Allocated     Qty Available      Qty on P.O.         Qty in Vessel           Qty on Sales Order
	M-0000.1001           4537              550               3987               25                   0						0
*/

--Use P21;

--Get Meyn parts

with getMeynParts(item_id,short_code, inv_mast_uid,qty_on_hand,qty_allocated,Qty_Available,Qty_on_po)
as
(
	select im.item_id,short_code, im.inv_mast_uid,qty_on_hand,qty_allocated,(qty_on_hand - qty_allocated)[Qty Available],order_quantity[Qty on P.O.]
	from inv_mast im
	join inv_loc l
	on im.inv_mast_uid = l.inv_mast_uid
	where im.item_desc like 'M-%' and (default_price_family_uid not in (5,34,38) or default_price_family_uid is null)
),
getSalesOrders(item_id,short_code, inv_mast_uid,qty_on_hand,qty_allocated,Qty_Available,Qty_on_po,qty_on_sales_order)
as
(
	select item_id,short_code, gdp.inv_mast_uid,qty_on_hand,qty_allocated,Qty_Available,Qty_on_po,ilss.qty_on_sales_order
	from getMeynParts gdp
	left join inv_loc_stock_status ilss
	on gdp.inv_mast_uid = ilss.inv_mast_uid
),
getVesselNumbers(inv_mast_uid,Qty_on_vessel)
as
(
	select inv_mast_uid,v.container_qty_received
	from po_line p
	join vessel_receipts_line v
	on p.po_line_uid = v.po_line_uid
	where qty_received = 0 and  p.complete = 'N'
)
select gso.item_id[Item ID],short_code,convert(int,qty_on_hand)[Qty on Hand],convert(int,qty_allocated,0)[Qty allocated],convert(int,Qty_Available,0)[Qty Available],convert(int,Qty_on_po,0)[Qty on P.O.],coalesce(convert(int,Qty_on_vessel,0),0)[Qty in Vessel],coalesce(convert(int,qty_on_sales_order,0),0)[Qty on Sales Order]
from getSalesOrders gso
left join  getVesselNumbers vn
on gso.inv_mast_uid = vn.inv_mast_uid
order by item_id
