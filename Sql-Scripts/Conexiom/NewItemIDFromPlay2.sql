with ctegetpartnumbs(upc_code,short_code,item_id,item_desc,out_upc,out_item_id,inv_mast_uid,default_sales_loc)
             as
             (
	            Select ivs.upc_code,
	                        case
		                        when im.short_code is null then mu.legacy_item_id
		                        else im.short_code End,
		                        mu.legacy_item_id,mu.legacy_item_description,ivs.upc_code,im.item_id,im.inv_mast_uid,class_id1
                            from inventory_supplier ivs
                            join inv_mast im
                            on ivs.inv_mast_uid = im.inv_mast_uid
							join inv_mast_ud mu
							on im.inv_mast_uid = mu.inv_mast_uid
                            where im.class_id2 = 'EPL' 
               
            ) 
            select upc_code,short_code,item_id,item_desc,il.location_id,default_sales_loc,out_upc,out_item_id,cpn.inv_mast_uid
            from ctegetpartnumbs  cpn
            join inv_loc il
            on cpn.inv_mast_uid = il.inv_mast_uid  
            where location_id in (100, 300) and default_sales_loc in ('IPTCI','PTI')
            order by inv_mast_uid    