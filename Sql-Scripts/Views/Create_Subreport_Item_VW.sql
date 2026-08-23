select line_no, item_id,qty_ordered , unit_of_measure,item_desc,l.primary_bin,l.qty_on_hand,(qty_on_hand - qty_frozen - qty_non_pickable - qty_quarantined)[ROH],order_no
from oe_line ol
join inv_mast m
on ol.inv_mast_uid = m.inv_mast_uid
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid and ol.source_loc_id = l.location_id
join inv_loc_stock_status s
on l.inv_mast_uid = s.inv_mast_uid and ol.source_loc_id = s.location_id
--where order_no = 1140118

order by primary_bin


select item_id,item_desc,l.primary_bin,l.qty_on_hand,(qty_on_hand - qty_frozen - qty_non_pickable - qty_quarantined)[ROH]
from inv_mast m
join inv_loc l
on m.inv_mast_uid = l.inv_mast_uid --and ol.source_loc_id = l.location_id
join inv_loc_stock_status s
on l.inv_mast_uid = s.inv_mast_uid --and ol.source_loc_id = s.location_id
--where order_no = 1140118

order by item_id