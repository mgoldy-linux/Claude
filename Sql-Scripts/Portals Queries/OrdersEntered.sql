/*
	05/05/2020 - create a query for orders taken in the last 48 hours, need logic for start & end date
	07/09/2020 - qry for portal
	Orders Entered – Quantity, lines and Revenue
	add salesrep & item_id, onhand qty
	what the best way to handle quanity to make?
*/
Declare @StartDate as varchar(12),
		@DayName as varchar(10);

Select @DayName = DATEName(DW,GETDATE())

Begin
if @DayName = 'Monday'
Begin
Set @StartDate = dateadd(day,datediff(day,3,GETDATE()),0)
End
Set @StartDate = convert(varchar(12),dateadd(day,datediff(day,1,GETDATE()),0),23)
End;

with getOrders(order_no, customer_id,ship2_name,taker, order_date, requested_date,po_no,po_no_append,promise_date,ups_code,unit_price,qty_ordered,qty_canceled,qty_per_assembly,extended_price,line_no,customer_part_number,inv_mast_uid)
as
(
	Select  h.order_no, customer_id,ship2_name,taker,convert(varchar(12),order_date,23),convert(varchar(12),requested_date,23),po_no,po_no_append,convert(varchar(12),promise_date,23)[promise_date],ups_code,format(round(unit_price,2),'C')[unit_price],cast(qty_ordered as int)[qty_ordered],cast(qty_canceled as int)[qty_canceled],cast(qty_per_assembly as int)[qty_per_assembly],format(round(extended_price,2) ,'c')[extended_price],line_no,customer_part_number,inv_mast_uid
	from oe_hdr h
	join oe_line l
	on h.order_no = l.order_no
	where order_date between @StartDate and GETDATE() and h.delete_flag = 'N' and l.delete_flag = 'N'  AND projected_order = 'N' and rma_flag = 'N'
)
select order_no, customer_id,ship2_name,taker, order_date, requested_date,po_no,po_no_append,promise_date,ups_code,unit_price,qty_ordered,cast(il.qty_on_hand as int)[qty_on_hand],qty_canceled,qty_per_assembly,extended_price,line_no,customer_part_number,gor.inv_mast_uid,il.location_id
from getOrders gor
join inv_loc il
on gor.inv_mast_uid = il.inv_mast_uid
order by  order_date, taker, line_no