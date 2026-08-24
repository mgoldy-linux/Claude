select class_id1,class_id2,*
from inv_mast
where inv_mast_uid =  48751 

-- check update dup epl
select  COUNT(*)[dup epl]
from inv_mast
where class_id2 = 'EPL'

select  COUNT(*)[dup notepl]
from inv_mast
where class_id2 = 'NOTEPL'

-- check zero price
select  COUNT(*)[zepl]
--select inv_mast_uid, item_id 
from inv_mast
where class_id2 = 'EPL' and price1 = 0

select  COUNT(*)[znotepl]
from inv_mast
where class_id2 = 'NOTEPL' and price1 = 0