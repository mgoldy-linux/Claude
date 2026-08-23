/*
	07/19/2021 - email from George
	Columns requested
	[Meyn Part#],[Unit Sales in FY2021],[Unit Sales in FY2020],[Qty on Hand],[Qty Allocated],[Qty Backordered],[Qty Available],[Qty on Purchase Order],[Qty in Vessel]
	item_id M-0008.4286 good benchmark inv_mast_uid = 16817
	07/23/2021 - fixed null qty - on vessel, add item description
*/

with getMeynParts
as
(
select item_id,item_desc,qty_on_hand,qty_allocated,qty_backordered,convert(int,(qty_on_hand - qty_allocated))[Qty Available],isnull(sum(qty_ordered),0)[rawQtyonPO],m.inv_mast_uid
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
left join inv_loc_stock_status s
on m.inv_mast_uid = s.inv_mast_uid
left join po_line p
on m.inv_mast_uid = p.inv_mast_uid and complete = 'N'
where item_id like 'M-%' 
group by item_id,item_desc,qty_on_hand,qty_allocated,qty_backordered,(qty_on_hand - qty_allocated),m.inv_mast_uid
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
Meyn2021(inv_mast_uid21,UnitSales2021)
as
(
	select inv_mast_uid,Sum(qty_shipped)
	from invoice_hdr h
	join invoice_line il
	on h.invoice_no = il.invoice_no
	where invoice_date between '2020-07-01' and '2021-06-30'
	group by inv_mast_uid
),
Meyn2020(inv_mast_uid20,UnitSales2020)
as
(
	select inv_mast_uid,Sum(qty_shipped)
	from invoice_hdr h
	join invoice_line il
	on h.invoice_no = il.invoice_no
	where invoice_date between '2019-07-01' and '2020-06-30'
	group by inv_mast_uid
)
select item_id[Meyn Part#],item_desc[Item Description],convert(int,isnull(M21.UnitSales2021,0))[Unit Sales in FY2021],convert(int,isnull(M20.UnitSales2020,0))[Unit Sales in FY2020],convert(int,qty_on_hand)[Qty on Hand],
convert(int,qty_allocated)[Qty Allocated],convert(int,qty_backordered)[Qty Backordered],[Qty Available],convert(int,(rawQtyonPO - isnull(Qty_on_vessel,0)))[Qty on Purchase Order],
convert(int,isnull(Qty_on_vessel,0))[Qty in Vessel]
from getMeynParts mp
left join getVesselNumbers vn
on mp.inv_mast_uid = vn.inv_mast_uid
left join Meyn2020 M20
on mp.inv_mast_uid = M20.inv_mast_uid20
left join Meyn2021 M21
on mp.inv_mast_uid = M21.inv_mast_uid21
order  by item_id
