/*
	testing addin quaranined
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
		select item_id,(L100 - gq.qty_quarantined),inv_mast_uid
		from get100Parts g100
		left join get100Quarantined gq
		on g100.inv_mast_uid = gq.qinv_mast_uid
	)
	select *
	from addInQuarantined100
