with get100Parts(item_id,L100,inv_mast_uid)
    as
    (
	    select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	    from inv_mast im
	    join inv_loc l
	    on im.inv_mast_uid = l.inv_mast_uid
	    where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 100 
    ),
	get100Quarantined(qinv_mast_uid,qty_quarantined,qty_non_pickable)
	as
	(
		select inv_mast_uid,qty_quarantined,qty_non_pickable
		from inv_loc_stock_status
		where location_id = 100
	),
	addInQuarantined100(item_id,L100,inv_mast_uid)
	as
	(
		select item_id,Floor(L100 - gq.qty_quarantined - qty_non_pickable),inv_mast_uid
		from get100Parts g100
		left join get100Quarantined gq
		on g100.inv_mast_uid = gq.qinv_mast_uid
	),
	updateAssy_QTM100(item_id,L100,inv_mast_uid)
	as
	(
		select q.item_id,
		case when tm.L100 is null then Coalesce(q.L100,0)
		else tm.L100
		end,q.inv_mast_uid
		from addInQuarantined100 q
		left join _assembly_QTM tm
		on q.item_id = tm.assy_id
	),
	get150Parts(item_id,L150,inv_mast_uid)
	as
	(
	   select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	   from inv_mast im
	   join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 150
    ),
	updateAssy150(item_id,L150,inv_mast_uid)
	as
	(
		select gp15.item_id,
		case when tm.L150 is null then Coalesce(gp15.L150,0)
		else tm.L150
		end,gp15.inv_mast_uid
		from get150Parts gp15
		left join _assembly_QTM tm
		on gp15.item_id = tm.assy_id
	),
	get200Parts(item_id,L200,inv_mast_uid)
	as
	(
	   select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	   from inv_mast im
	   join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 200
    ),
	updateAssy200(item_id,L200,inv_mast_uid)
	as
	(
		select gp2.item_id,
		case when tm.L200 is null then Coalesce(gp2.L200,0)
		else tm.L200
		end,gp2.inv_mast_uid
		from get200Parts gp2
		left join _assembly_QTM tm
		on gp2.item_id = tm.assy_id
	),
	get300Parts(item_id,L300,inv_mast_uid)
	as
	(
	   select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	   from inv_mast im
	   join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 300
	 ),
	updateAssy300(item_id,L300,inv_mast_uid)
	as
	(
		select gp3.item_id,
		case when tm.L300 is null then Coalesce(gp3.L300,0)
		else tm.L300
		end,gp3.inv_mast_uid
		from get300Parts gp3
		left join _assembly_QTM tm
		on gp3.item_id = tm.assy_id
	),
	get350Parts(item_id,L350,inv_mast_uid)
	as
	(
	   select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	   from inv_mast im
	   join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 350
	 ),
	updateAssy350(item_id,L350,inv_mast_uid)
	as
	(
		select gp35.item_id,
		case when tm.L350 is null then Coalesce(gp35.L350,0)
		else tm.L350
		end,gp35.inv_mast_uid
		from get350Parts gp35
		left join _assembly_QTM tm
		on gp35.item_id = tm.assy_id
	),
	 combine100200(item_id,L100,L200,inv_mast_uid)
	 as
	 (
		select g1.item_id,Coalesce(L100,0),Coalesce(L200,0),g1.inv_mast_uid
		from updateAssy_QTM100 g1
		left join updateAssy200 g2
		on g1.item_id = g2.item_id
	),
	addIn150(item_id,L100,L150,L200,inv_mast_uid)
	as
	(
	select c12.item_id,L100,Coalesce(g15.L150,0),L200,c12.inv_mast_uid
	from combine100200 c12
	left join updateAssy150 g15
	on c12.item_id = g15.item_id
	),
	addIn300(item_id,L100,L150,L200,L300,inv_mast_uid)
	as
	(
	select a15.item_id,L100,L150,L200,Coalesce(g3.L300,0),a15.inv_mast_uid
	from addIn150 a15
	left join updateAssy300 g3
	on a15.item_id = g3.item_id
	)
	select a3.item_id,L100[0],L150[1],L200[2],L300[3],Coalesce(g35.L350,0)[4]
	from addIn300 a3
	left join updateAssy350 g35
	on a3.item_id = g35.item_id
	--where a3.item_id like '3535%'
	where a3.item_id = '1610-1-3/8'