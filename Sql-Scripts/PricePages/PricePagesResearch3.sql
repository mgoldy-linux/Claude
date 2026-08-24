select default_product_group,def
from inv_mast 
--where inv_mast_uid = 50223
--where item_id = 'SUCNF215-47'
where upc_or_ean_id = '80067532814'

select *
from inv_loc
where inv_mast_uid = 24571

select *
from item_uom
where inv_mast_uid = 50223


select *
from new_ids
where inv_mast_uid = 50223

select *
from product_group


select price1,(price1*1.09)[New Price],Floor(price1*1.09)[Test]
from inv_mast
where inv_mast_uid = 50223
