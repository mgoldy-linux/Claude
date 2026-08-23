select item_id,qty_on_hand,location_id,sellable
from  inv_mast im
join inv_loc l
on im.inv_mast_uid = l.inv_mast_uid
where class_id1 = 'IPTCI' and class_id2 = 'EPL' and im.delete_flag = 'N' and im.ecc_enabled_flag = 'Y'-- and qty_on_hand > 0 
order by item_id


select  *
from inv_mast
where item_id in ('39B100001-BOX','F212')