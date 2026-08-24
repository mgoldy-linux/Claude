select l.order_no[Order_No],item_id[Item_ID],item_desc[Description],convert(int,qty_ordered)[Qty-Ordered],replace(convert(varchar(12),h.requested_date, 110),'-','/')[Required_Date],
replace(convert(varchar(12),h.promise_date, 110),'-','/')[Promise_Date],
convert(int,(qty_ordered - isnull(d.ship_quantity,0)))[Qty-Outstanding],po_no[MEYN-PO_NO],isnull(l.disposition,'-')[Disposition]
from inv_mast m
join oe_line l
on m.inv_mast_uid = l.inv_mast_uid and l.complete = 'N'
join oe_hdr h
on l.order_no = h.order_no
left join oe_pick_ticket p
on h.order_no = p.order_no and p.delete_flag = 'N'
left join oe_pick_ticket_detail d
on p.pick_ticket_no = d.pick_ticket_no and m.inv_mast_uid = d.inv_mast_uid 
where item_id like 'M-%' and l.delete_flag = 'N' and h.completed = 'N' and rma_flag = 'N' and (qty_ordered - isnull(ship_quantity,0)) > 0 and h.projected_order = 'N'and l.disposition = 'B'
order by h.order_no

select l.order_no[Order_No],item_id[Item_ID],item_desc[Description],convert(int,qty_ordered)[Qty-Ordered],
replace(convert(varchar(12),h.promise_date, 110),'-','/')[Promise_Date],
convert(int,(qty_ordered - isnull(d.ship_quantity,0)))[Qty-Outstanding],po_no[MEYN-PO_NO],isnull(l.disposition,'-')[Disposition]
from inv_mast m
join oe_line l
on m.inv_mast_uid = l.inv_mast_uid and l.complete = 'N'
join oe_hdr h
on l.order_no = h.order_no
left join oe_pick_ticket p
on h.order_no = p.order_no and p.delete_flag = 'N'
left join oe_pick_ticket_detail d
on p.pick_ticket_no = d.pick_ticket_no and m.inv_mast_uid = d.inv_mast_uid 
where item_id like 'M-%' and l.delete_flag = 'N' and h.completed = 'N' and rma_flag = 'N' and (qty_ordered - isnull(ship_quantity,0)) > 0 and h.projected_order = 'N'
order by h.order_no
