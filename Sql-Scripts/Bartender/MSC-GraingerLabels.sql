select upc_or_ean, item_desc,item_id
from inv_mast
--where item_id = '2101081448'

where inv_mast_uid = 83785

select *
from inventory_supplier
where inv_mast_uid = 83785

select distinct x.customer_id, c.customer_name
from inv_xref x
join customer c
on x.customer_id = c.customer_id
order by x.customer_id desc

-- 49889 MSC, 54210 Grainger 
select their_item_id,upc_code,item_desc,item_id,m.class_id1[Brand]
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid 
left join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where customer_id = 54210 


select m.inv_mast_uid,x.their_item_id,item_desc, item_id, upc_code,class_id5
from inv_mast m
join inventory_supplier s 
on m.inv_mast_uid = s.inv_mast_uid
left join inv_xref x
on x.inv_mast_uid = m.inv_mast_uid 
where class_id5 in ('MSCPACK', 'GRAINGER') and m.delete_flag = 'N'

