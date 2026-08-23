with ctegetpartnumbs(short_code,item_id,item_desc,out_upc,out_item_id,inv_mast_uid,default_sales_loc,pricelist)
             as
             (
	            Select     case
		                        when im.short_code is null then im.item_id
		                        else im.short_code End,
		                        im.item_id,im.item_desc,ivs.upc_code,im.item_id,im.inv_mast_uid,class_id1,class_id2
                            from inventory_supplier ivs
                            join inv_mast im
                            on ivs.inv_mast_uid = im.inv_mast_uid
                           -- where im.class_id2 = 'EPL' 
            ) 
            select short_code,item_id,item_desc,il.location_id,default_sales_loc,out_item_id,Convert(Int,Sum(number_of_orders))[number_of_orders],Convert(int,Sum(inv_period_usage))[Total_Usage]
            from ctegetpartnumbs  cpn
            join inv_loc il
            on cpn.inv_mast_uid = il.inv_mast_uid 
			left join inv_period_usage ipu
			on cpn.inv_mast_uid = ipu.inv_mast_uid
            where il.location_id = 300 and discontinued = 'N' and stockable = 'Y' and default_sales_loc = 'IPTCI' /*and item_id not like '%[BTO]%'*/ and item_id not in ('222222') 
			group by short_code,item_id,item_desc,il.location_id,default_sales_loc,out_item_id
            order by short_code
/*
		select inv_mast_uid,Sum(number_of_orders)[number_of_orders], Sum(inv_period_usage)[Total_Usage]
		from inv_period_usage
		where location_id = 300 and inv_mast_uid in (30888,30889,30890)
		Group by inv_mast_uid

		select *
		from demand_period
		order by demand_period_uid desc

		select inv_mast_uid
		from inv_mast
		where short_code like 'BUCNPP 204 12%'
		
		--create ps script find part info
		select location_id,discontinued,discontinued_date,sellable,stockable,m.inv_mast_uid,short_code,item_desc,m.delete_flag,class_id2
		from inv_loc l
		join inv_mast m
		on l.inv_mast_uid = m.inv_mast_uid
		where item_id = '66G233801-BOX[BTO]'
*/