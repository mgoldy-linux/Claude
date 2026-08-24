exec sp_help oe_hdr

select distinct order_type
from oe_hdr

select *
from code_p21
where code_no in (0,1,2)

select distinct detail_type
from oe_line

select *
from assembly_hdr
where inv_mast_uid = 816

select *
from assembly_line
where component_inv_mast_uid = 816

select *
from inv_mast 
where inv_mast_uid = 37211
where item_id in ('2101001052','2101019066','2101027418')


select inv_mast_uid,*
from oe_line
where detail_type = 1