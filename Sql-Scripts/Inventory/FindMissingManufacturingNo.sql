select  class_id1,item_id,item_desc,s.supplier_id,a.name,s.manufacturing_class_id
from inv_mast m
join inventory_supplier	s
on m.inv_mast_uid = s.inv_mast_uid
join address a
on s.supplier_id = a.id
where manufacturing_class_id is null and m.delete_flag = 'N' --and class_id1 in ('IPTCI','LMS','PTI','TRITAN')
order by class_id1


