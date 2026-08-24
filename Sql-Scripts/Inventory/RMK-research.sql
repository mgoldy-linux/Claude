select default_product_group,*
from inv_mast
where item_id like 'Hc204%'

select *
from inv_xref
where their_item_id like 'HC206%'