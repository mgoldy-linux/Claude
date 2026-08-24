-- MSC customer ID = 12945
Use P21Sand;

select customer_name, trading_partner_name,class_2id,trading_partner_name,*
from customer
where customer_name like '%MSC%' and delete_flag = 'N'


select their_item_id,item_id[SIMG],item_desc,extended_desc ,x.customer_id,x.inv_mast_uid,x.inv_xref_uid,x.date_created,x.created_by,c.customer_name
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
join dbo.customer c
on x.customer_id = c.customer_id
where their_item_id = '17040866'--item_id = '2101067690' --item_desc like '%100E36%' 

select their_item_id,item_id[SIMG],item_desc,extended_desc ,customer_id,x.inv_mast_uid,x.inv_xref_uid,x.date_created,x.created_by
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where  customer_id = 12945 and their_item_id = '17040866' --and item_id = '2101067690' --item_desc like '%100E36%' 