select customer_name, trading_partner_name,*
from customer
where customer_name like '%Fast%' and delete_flag = 'N' and class_2id = 'FASTENAL' and trading_partner_name = '042653634G'

select their_item_id,item_id[SIMG],item_desc,customer_id,x.inv_mast_uid
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where their_item_id = '4123765' and customer_id in (16425,50711,52591)

select *
from inv_mast
where item_id = '2100252509'

select *
from inv_mast 
where item_desc = '02420'

select their_item_id,item_id[SIMG],item_desc,cast(customer_id as int)customer_id,u.legacy_description,u.legacy_id,u.legacy_item_id
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
join dbo.inv_mast_ud u
on m.inv_mast_uid = u.inv_mast_uid 
where item_desc like '02420%' and customer_id = 16425

select their_item_id,item_id[SIMG],item_desc,cast(customer_id as int)customer_id
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where item_desc like '08BS1%' and customer_id = 16425


select customer_name
from customer
where customer_id in (50711,52591)

select *
from dbo.inv_xref x
where their_item_id = '4123765'

