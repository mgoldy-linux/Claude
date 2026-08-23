--80067532991, 24877

select upc_or_ean_id, *
from inv_mast
where item_id = 'UCF20720RM'

select *
from inventory_supplier
where inv_mast_uid = 24877

select their_item_id,*
from inv_xref
where inv_mast_uid in (27740,24877)