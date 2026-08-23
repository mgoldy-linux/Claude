-- missing craig

with getInsideUsers 
as
(
	select u.id,u.name,role,default_branch
	from roles r
	join users u
	on r.role_uid = u.role_uid
	where (r.role like '%inside%'  or r.role like '%EDI%') and r.delete_flag = 'N' and u.delete_flag = 'N'
	),
getOpenOrders(customer_id, order_no,order_date,ship2_name,requested_date,po_no,taker)
as
(
	select customer_id, order_no,replace(convert(varchar(12),order_date, 110),'-','/'),ship2_name,replace(convert(varchar(12),requested_date, 110),'-','/'),po_no,taker
	from getInsideUsers gis
	join oe_hdr h
	on gis.id = h.taker
	where approved = 'Y' and completed = 'N' and name = 'Ray Carter' and projected_order = 'N' and delete_flag = 'N' and cancel_flag = 'N'
),
getPickTickets(taker,customer_id,order_no,order_date,ship2_name,requested_date,po_no,pick_ticket_no,invoice_no)
as
(
	select taker,customer_id,goo.order_no,order_date,ship2_name,requested_date,po_no,pick_ticket_no,invoice_no
	from getOpenOrders goo
	join oe_pick_ticket opt
	on goo.order_no = opt.order_no
	group by taker,customer_id,order_date,goo.order_no,ship2_name,requested_date,po_no,pick_ticket_no,invoice_no
),
getOrderLine(taker,customer_id,order_no,order_date,ship2_name,requested_date,po_no,expedite_date,pick_ticket_no,invoice_no,inv_mast_uid,item_id,customer_part_number,qty_ordered,qty_remaining2ship,line_no)
as
(
	select taker,customer_id,gpt.order_no,order_date,ship2_name,requested_date,po_no,replace(convert(varchar(12),expedite_date, 110),'-','/')[expedite_date],pick_ticket_no,invoice_no,inv_mast_uid,item_id,customer_part_number,qty_ordered,qty_allocated,line_no
	from getPickTickets gpt
	join p21_view_oe_line ol
	on gpt.order_no = ol.order_no
	--where gpt.order_no = 1097225
)
-- removed gol.inv_mast_uid,
select taker,customer_id,order_no,gol.pick_ticket_no,invoice_no,ship2_name,requested_date,po_no,order_date,expedite_date,line_no,gol.item_id,qty_ordered,qty_remaining2ship
from getOrderLine gol
join p21_view_support_sql_salesorder_oe_pick_ticket_detail ptd
on gol.pick_ticket_no = ptd.pick_ticket_no and gol.item_id = ptd.item_id
where gol.line_no = ptd.line_number
group by taker,customer_id,order_no,order_date,ship2_name,requested_date,po_no,expedite_date,gol.pick_ticket_no,invoice_no,line_no,gol.item_id,qty_ordered,qty_remaining2ship,ptd.ship_quantity
order by customer_id,order_no--;exec p21_get_qty_to_make 'UCFCX08-24', 28007, 100, 0

/*
select *
from p21_view_support_sql_salesorder_oe_pick_ticket_detail
where pick_ticket_no = 2015818


-- qty open - qty_ordered - (qty_allocated + qty_invoiced)
select *
from p21_view_oe_line
where order_no = 1064822


/*
select *
from oe_hdr
where order_no = 1106453

select *
from invoice_hdr 
where order_no = '1106453'

select *
from oe_pick_ticket
--where order_no = 1020647
where order_no = 1064822
*/

select inv_mast_uid,order_no,qty_ordered,unit_quantity,date_created,*
from oe_line
where order_no = 1064822
--where qty_ordered > unit_quantity

select *
from p21_view_open_transfers_report

select Sum(qty_invoiced),inv_mast_uid
from oe_line_schedule
where order_no = 1013641
group by inv_mast_uid
--order by release_date desc

select *
from oe_schedule
where order_number = 1000504

declare @MyTableType as table
(
	QTY_TO_MAKE int
)  

Insert into @MyTableType 
exec p21_get_qty_to_make 'UCFCX08-24', 28007, 100, 0

SELECT QTY_TO_MAKE
FROM @MyTableType



select *
from p21_view_support_sql_salesorder_oe_pick_ticket_detail ptd
where order_no = 1013641 and inv_mast_uid = 28007 and printed = 'Y'

select *
from dbo.p21_fnt_all_pick_ticket_line (2015818, 2015818,100)

select *
from dbo.p21_fnt_assembly_components_cutoff (28007)


select line_number,item_id,print_quantity,ship_quantity
from oe_pick_ticket_detail p
join inv_mast im
on p.inv_mast_uid = im.inv_mast_uid
where pick_ticket_no = 2079882

select *
from oe_pick_ticket
where  pick_ticket_no = 2079882
*/