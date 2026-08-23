select class_id1, class_id5
from inv_mast
where item_id = 'FREIGHTOUT'

Update inv_mast
set class_id1 = NULL,class_id5 = Null
where item_id = 'FREIGHTOUT'

select class_id1, class_id5
from inv_mast
where item_id = 'FREIGHTOUT'