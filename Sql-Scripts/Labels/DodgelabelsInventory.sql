-- are dodge lables in stock?

select inv_mast_uid,item_id,item_desc,generic_item_desc,short_code
from inv_mast
where item_desc like '%label%'

select *
from inv_loc
where inv_mast_uid = '40796'