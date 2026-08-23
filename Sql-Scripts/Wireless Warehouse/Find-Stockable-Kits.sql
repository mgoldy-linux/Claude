SELECT     m.item_id,m.item_desc,l.stockable,qty_on_hand,track_bins,prim
FROM         dbo.inv_mast m
INNER JOIN    dbo.assembly_hdr 
ON dbo.assembly_hdr.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid and l.location_id = 100
WHERE     (dbo.assembly_hdr.production_order_processing = 'N') AND (dbo.assembly_hdr.delete_flag = 'N') and stockable = 'N' and qty_on_hand > 0
