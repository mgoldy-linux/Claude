select inv_mast_uid,item_id,short_code,item_desc,class_id2,ecc_enabled_flag
from inv_mast
where item_id in ('62O471601-BOX','62O471601-BOX[BTO]','39J313403-BOX')

select inv_mast_uid,location_id,stockable,product_group_id,buy,make,discontinued
from inv_loc
where inv_mast_uid in (45412, 39051,43225)