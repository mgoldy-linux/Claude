use P21Sand;

Select item_id,si.inv_mast_uid,cost, (cost *.95)[New_Cost],supplier_id
from inventory_supplier si
join inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where division_id in (46788,58981) and cost > 0

Select item_id,si.inv_mast_uid,cost, (cost *.95)[New_Cost]
from inventory_supplier si
join inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where division_id = 58981 and cost > 0

Select item_id,si.inv_mast_uid,cost, (cost *.95)[New_Cost]
from inventory_supplier si
join inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where division_id = 46788 and cost > 0

Select item_id,si.inv_mast_uid,cost, (cost *.95)[New_Cost],supplier_id
from inventory_supplier si
join inv_mast m
on si.inv_mast_uid = m.inv_mast_uid
where division_id in (46788,58981) and cost > 0
