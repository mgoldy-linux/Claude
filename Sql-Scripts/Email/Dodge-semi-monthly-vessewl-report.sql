with getOpenPOs(po_no,item_description,qty_ordered,qty_received,inv_mast_uid,po_line_uid,complete)
                    as
                    (
	                    select h.po_no,item_description,qty_ordered,qty_received,inv_mast_uid,po_line_uid,l.complete
	                    from po_hdr h
	                    join po_line l 
	                    on h.po_no = l.po_no
	                    where l.complete = 'N'
                    )
                    select po_no,item_id,item_description,format(qty_ordered,'N0')[qty_ordered],format(qty_backordered,'N0')[qty_backordered],format(vrh.arrival_date,'MM/dd/yyyy')[est_arrival_date],vrc.container_name
                    from getOpenPOs gop
                    join inv_mast im
                    on gop.inv_mast_uid = im.inv_mast_uid
                    join vessel_receipts_line v
                    on gop.po_line_uid = v.po_line_uid
                    join vessel_receipts_hdr vrh
                    on vrh.vessel_receipts_hdr_uid = v.vessel_receipts_hdr_uid
                    join inv_loc il
                    on im.inv_mast_uid = il.inv_mast_uid
                    join vessel_receipts_container vrc
                    on vrh.vessel_receipts_hdr_uid = vrc.vessel_receipts_hdr_uid
                    where default_product_group = 'D1' and qty_received = 0 and gop.complete = 'N' 
                    order by item_id