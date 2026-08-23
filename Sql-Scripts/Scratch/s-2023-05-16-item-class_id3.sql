select *
from vwWQReportLog
where User_name = 'George Dib'

select item_id, class_id2,l.location_id
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where class_id3 ='All'
order by item_id

select *
from location 