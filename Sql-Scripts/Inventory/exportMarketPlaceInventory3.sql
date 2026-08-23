/*
<#
    02/14/2020 - Created exporting PTI parts for Ftp
    \\pti-sql1\PTI Stock List\Output
    sample name: PTIStockList_01-08-2018.csv
    04\22\2020 changed qty_on_hand to (qty_on_hand - qty_allocated) pre Craig's recommendation
	04/29/2020 add inv_loc_stock_status_ qty_quarantined
#>
*/
with get100Parts(item_id,L100,inv_mast_uid)
    as
    (
	    select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	    from inv_mast im
	    join inv_loc l
	    on im.inv_mast_uid = l.inv_mast_uid
	    where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 100 
    ),
	get100Quarantined(qinv_mast_uid,qty_quarantined)
	as
	(
		select inv_mast_uid,qty_quarantined
		from inv_loc_stock_status
		where location_id = 100
	),
	addInQuarantined100(item_id,L100,inv_mast_uid)
	as
	(
		select item_id,Floor(L100 - gq.qty_quarantined),inv_mast_uid
		from get100Parts g100
		left join get100Quarantined gq
		on g100.inv_mast_uid = gq.qinv_mast_uid
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
	get200Parts(item_id,L200,inv_mast_uid)
	as
	(
	   select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	   from inv_mast im
	   join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 200
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
	 get350Parts(item_id,L350,inv_mast_uid)
	as
	(
	   select im.item_id,FLOOR(qty_on_hand - qty_allocated),im.inv_mast_uid
	   from inv_mast im
	   join inv_loc l
	   on im.inv_mast_uid = l.inv_mast_uid
	   where im.class_id2 = 'EPL' and im.class_id1 = 'PTI' and location_id = 350
	 ),
	 combine100200(item_id,L100,L200,inv_mast_uid)
	 as
	 (
		select g1.item_id,Coalesce(L100,0),Coalesce(L200,0),g1.inv_mast_uid
		from addInQuarantined100 g1
		left join get200Parts g2
		on g1.item_id = g2.item_id
	),
	addIn150(item_id,L100,L150,L200,inv_mast_uid)
	as
	(
	select c12.item_id,L100,Coalesce(g15.L150,0),L200,c12.inv_mast_uid
	from combine100200 c12
	left join get150Parts g15
	on c12.item_id = g15.item_id
	),
	addIn300(item_id,L100,L150,L200,L300,inv_mast_uid)
	as
	(
	select a15.item_id,L100,L150,L200,Coalesce(g3.L300,0),a15.inv_mast_uid
	from addIn150 a15
	left join get300Parts g3
	on a15.item_id = g3.item_id
	),
	addIn350(item_id,L100,L150,L200,L300,L350,inv_mast_uid)
	as
	(
	select a3.item_id,L100,L150,L200,L300,Coalesce(g35.L350,0),a3.inv_mast_uid
	from addIn300 a3
	left join get350Parts g35
	on a3.item_id = g35.item_id
	)
	select a3.item_id,L100[0],L150[1],L200[2],L300[3],Coalesce(g35.L350,0)[4]
	from addIn300 a3
	left join get350Parts g35
	on a3.item_id = g35.item_id