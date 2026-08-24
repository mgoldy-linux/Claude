/*
	start 01/13/2020
	reference
	select item_id, item_desc,fifo_layer_number,fifo_layer_qty, cost
	from inv_mast i
	join fifo_layers f
	on i.inv_mast_uid = f.inv_mast_uid
	where location_id = 300


	!not working !

*/
use P21;

select *
from (
	select item_id,item_desc,f.location_id,fifo_layer_qty,cost
	from inv_mast i
	join fifo_layers f
	on i.inv_mast_uid = f.inv_mast_uid
	where location_id = 300
) as SourceData
pivot
(
	Count(location_id)
	For [location_id] in ([1],[2],[3],[4],[5])
)as Piv


select top 5 *
from fifo_layers