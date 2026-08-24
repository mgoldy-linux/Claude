select a.name[DXP_Branch_Name],default_branch_id[PTI_Default_Branch],left(a.phys_postal_code,5)[Zip_Code],customer_id
from customer c	
join address a
on c.customer_id = a.id
where c.class_2id = 'DXP' and c.delete_flag = 'N' and a.name not like 'AD%' --and a.name not like '%Bill To'
order by Zip_Code

