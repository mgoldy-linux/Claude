Use P21Play;
Select item_id,si.inv_mast_uid,cost, (cost *.95)[New_Cost],supplier_id
from inventory_supplier si
join inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where division_id in (46788,58981) and cost > 0  and item_id = '2100039330'

Use P21;
Select distinct item_id,si.inv_mast_uid,cost, (cost *.95)[New_Cost],supplier_id
from inventory_supplier si
join inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where division_id in (46788,58981) and cost > 0  and item_id = '2100039330'


Use Play2;
Select distinct item_id,si.inv_mast_uid,cost, (cost *.95)[New_Cost],supplier_id
from inventory_supplier si
join inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where division_id in (46788,58981) and cost > 0  and item_id = '2100039330'
