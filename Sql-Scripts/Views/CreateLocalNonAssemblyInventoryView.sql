/*	
	Rev 2 for Marketplace, can you include PTI parts for the following locations: 100,150,200,300 & 350 
feedback from end user - Second are you able to get it to us in a format more like this
"03B-100A",0,1,2,3,4

Where it is part number, Charlotte inventory, LA inventory, Denver Inventory, Chanhassen inventory, Portland inventory?

03/11/2020	Need to add assembly qty to make, cannot filter on class because need all componets for assembly
*/
--use P21Play;
use P21Local;

go
/*
if OBJECT_ID ('dnon_assemblyInventory', 'V') is not null
drop view dnon_assemblyInventory;
go
create view [dbo].[dnon_assemblyInventory] AS
*/

with get100Parts(inv_mast_uid,item_id,L100,class_id1,class_id2)
    as
    (
	    select im.inv_mast_uid,im.item_id,FLOOR(qty_on_hand),class_id1,class_id2
	    from inv_mast im
	    left join inv_loc l
	    on im.inv_mast_uid = l.inv_mast_uid
	    where  location_id = 100
    ),
	get150Parts(inv_mast_uid,item_id,L150,class_id1,class_id2)
	as
	(
	   select im.inv_mast_uid,im.item_id,FLOOR(qty_on_hand),class_id1,class_id2
	   from inv_mast im
	   left join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where  location_id = 150
    ),
	get200Parts(inv_mast_uid,item_id,L200,class_id1,class_id2)
	as
	(
	   select im.inv_mast_uid,im.item_id,FLOOR(qty_on_hand),class_id1,class_id2
	   from inv_mast im
	   left join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where  location_id = 200
    ),
	get300Parts(inv_mast_uid,item_id,L300,class_id1,class_id2)
	as
	(
	   select im.inv_mast_uid,im.item_id,FLOOR(qty_on_hand),class_id1,class_id2
	   from inv_mast im
	   left join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where  location_id = 300
	 ),
	 get350Parts(inv_mast_uid,item_id,L350,class_id1,class_id2)
	as
	(
	   select im.inv_mast_uid,im.item_id,FLOOR(qty_on_hand),class_id1,class_id2
	   from inv_mast im
	   left join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where  location_id = 350
	 ),
	 combine100200(inv_mast_uid,item_id,L100,L200,class_id1,class_id2)
	 as
	 (
		select case when g1.inv_mast_uid is null then g2.inv_mast_uid
		else g1.inv_mast_uid end,
		case when g1.item_id is null then g2.item_id
		else g1.item_id end,Coalesce(L100,0),Coalesce(L200,0),
		case when g1.class_id1 is null then g2.class_id1
		else g1.class_id1 end,
		case when g1.class_id2 is null then g2.class_id2
		else g1.class_id2 end
		from get100Parts g1
		full outer join get200Parts g2
		on g1.item_id = g2.item_id
	),
	addIn150(inv_mast_uid,item_id,L100,L150,L200,class_id1,class_id2)
	as
	(
	select case when c12.inv_mast_uid is null then g15.inv_mast_uid
	else c12.inv_mast_uid end,
	case when c12.item_id IS NULL then g15.item_id
	else c12.item_id end,L100,Coalesce(g15.L150,0),L200,
	case when c12.class_id1 is null then g15.class_id1
	else c12.class_id1 end,
	case when c12.class_id2 is null then g15.class_id2
	else c12.class_id2 end
	from combine100200 c12
	full outer join get150Parts g15
	on c12.item_id = g15.item_id
	),
	addIn300(inv_mast_uid,item_id,L100,L150,L200,L300,class_id1,class_id2)
	as
	(
	select case when a15.inv_mast_uid is null then g3.inv_mast_uid
	else a15.inv_mast_uid end,
	case when a15.item_id is null then g3.item_id
	else a15.item_id end,L100,L150,L200,Coalesce(g3.L300,0),
	case when a15.class_id1 is null then g3.class_id1
	else a15.class_id1 end,
	case when a15.class_id2 is null then g3.class_id2
	else a15.class_id2 end
	from addIn150 a15
	full outer join get300Parts g3
	on a15.item_id = g3.item_id
	)
	select case when a3.inv_mast_uid is null then g35.inv_mast_uid
	else a3.inv_mast_uid end[inv_mast_uid],
	case when a3.item_id is null then g35.item_id
	else a3.item_id end[item_id],Coalesce(L100,0)[L100],Coalesce(L150,0)[L150],Coalesce(L200,0)[L200],L300,Coalesce(g35.L350,0)[L350],
	case when a3.class_id1 is null then g35.class_id1
	else a3.class_id1 end[class_id1],
	case when a3.class_id2 is null then g35.class_id2
	else a3.class_id2 end[class_id2]
	from addIn300 a3
	full outer join get350Parts g35
	on a3.item_id = g35.item_id
	--order by a3.inv_mast_uid

	