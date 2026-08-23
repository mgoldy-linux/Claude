select item_id, item_desc, m.date_created, m.last_maintained_by,*
from inv_loc l
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
where location_id = 530 and class_id1 != 'EZO' and m.last_maintained_by != 'administrator'


select distinct m.last_maintained_by
from inv_loc l
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
where location_id = 530 and class_id1 != 'EZO' 

from  Bar_MD_Items_VW
where iten_desc like '%2012-1/2%'

select item_id, item_desc, class_id1, m.date_created, m.last_maintained_by,m.date_last_modified
from inv_loc l
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
where location_id = 530  and m.last_maintained_by in ('MITCH.DUTTON','JSCALA','TGLIGANIC','LANSEL','JIM.KOLESAR','PTIDOM\MITCH.DUTTON','PTIDOM\LARRY.KRAUS')

select distinct m.last_maintained_by
from inv_loc l
join inv_mast m
on m.inv_mast_uid = l.inv_mast_uid
where location_id = 530 