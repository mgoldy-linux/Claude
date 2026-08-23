
with GetLoc100(item_id100) 
as
(
Select top 5 item_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where qty_on_hand > 0 and location_id = 100 and class_id1 != 'LMS' and class_id2 = 'EPL'
),
GetLoc300(item_id300) 
as
(
Select top 5 item_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where qty_on_hand > 0 and location_id = 300 and class_id1 != 'LMS' and class_id2 = 'EPL'
),
GetLoc410(item_id410) 
as
(
Select top 5 item_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where qty_on_hand > 0 and location_id = 410 and class_id1 != 'LMS' and class_id2 = 'EPL'
),
GetLoc420(item_id420) 
as
(
Select top 5 item_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where qty_on_hand > 0 and location_id = 420 and class_id1 != 'LMS' and class_id2 = 'EPL'
),
GetLoc430(item_id430) 
as
(
Select top 5 item_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where qty_on_hand > 0 and location_id = 430 and class_id1 != 'LMS' and class_id2 = 'EPL'
),
GetLoc450(item_id450) 
as
(
Select top 5 item_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where qty_on_hand > 0 and location_id = 450 and class_id1 != 'LMS' and class_id2 = 'EPL'
),
GetLoc470(item_id470) 
as
(
Select top 5 item_id
from dbo.inv_mast m
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where qty_on_hand > 0 and location_id = 470 and class_id1 != 'LMS' and class_id2 = 'EPL'
)
select coalesce(item_id100,item_id300,item_id410,item_id420,item_id430,item_id450,item_id470) [item_id]
from GetLoc100 l1
full outer join GetLoc300 l3
on l1.item_id100 = l3.item_id300
full outer join GetLoc410 l41
on l1.item_id100 = l41.item_id410
full outer join GetLoc420 l42
on l1.item_id100 = l42.item_id420
full outer join GetLoc430 l43
on l1.item_id100 = l43.item_id430
full outer join GetLoc450 l45
on l1.item_id100 = l45.item_id450
full outer join GetLoc470 l47
on l1.item_id100 = l47.item_id470
order by item_id

