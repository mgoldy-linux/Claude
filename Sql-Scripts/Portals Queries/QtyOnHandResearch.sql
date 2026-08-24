/*
'Qty Available' is not retrieved from the database; no database information available.
The value is derived as if( ( inv_loc_qty_on_hand  - if( inv_loc_qty_allocated < 0, 0,  inv_loc_qty_allocated) - qty_non_pickable - qty_quarantined - qty_frozen  - if(isNull(qty_reserved), 0, qty_reserved))   /  unit_size < 0, 0 ,   (inv_loc_qty_on_hand  - if( inv_loc_qty_allocated < 0, 0, inv_loc_qty_allocated )  - qty_non_pickable - qty_quarantined - qty_frozen  - if(isNull(qty_reserved), 0, qty_reserved))  /  unit_size).
Column datatype is number.
The table to be updated is oe_line.
The field name is quantity_available
The column usage is: .
DataWindow Name: items
Window Name: w_order_entry_sheet
URL Handler Menu Name: m_orderentry
*/

-- qty on hand without qty to make. Make into function

with getBasicPartOnHand(inv_mast_uid,Qty_AvaliablePre)
as
(
	select il.inv_mast_uid,(qty_on_hand - qty_allocated - qty_non_pickable - qty_quarantined - qty_frozen) --qty_reserved
	from inv_loc il
	join inv_loc_stock_status ilss
	on il.inv_mast_uid = ilss.inv_mast_uid
)
select gBPH.inv_mast_uid,(Qty_AvaliablePre -  ISNULL(qty_reserved, 0))[Qty_Avaliable]
from getBasicPartOnHand gBPH
left join transfer_line tl 
on gBPH.inv_mast_uid = tl.inv_mast_uid and year(tl.date_created) = year(getdate()) and month(tl.date_created) = month(getdate()) and day(tl.date_created) = day(getdate())



select  *
from transfer_line
where inv_mast_uid = 37724


exec p21_get_qty_to_make  @item_uid = 1105, @include_item_qty = '$item_id', @location_id = 100, @revision_uid = 0



select order_no,inv_mast_uid ,qty_ordered,qty_per_assembly,assembly,parent_oe_line_uid,oe_line_uid,detail_type
from oe_line
where order_no = 1086166

select *
from assembly_line
where inv_mast_uid = 25923

select order_no,inv_mast_uid ,qty_ordered,qty_per_assembly,assembly,parent_oe_line_uid,oe_line_uid,detail_type
from oe_line
where assembly is null

declare	 @testText varchar(255),
		 @List NVARCHAR(MAX) = '',
		 @PTLineNubmebr int,
		 @testQty int;
-- return item id
select @testText = dbo.p21_fn_item_id (37791)
select @testText[item_id]
