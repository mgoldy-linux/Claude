Use P21Sand;

select customer_name, trading_partner_name,class_2id,trading_partner_name,*
from customer
where customer_name like '%Zoro%' and delete_flag = 'N'

select their_item_id,item_id[SIMG],item_desc,extended_desc ,customer_id,x.inv_mast_uid,x.inv_xref_uid,x.date_created,x.created_by
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where  customer_id = 55932  and item_id = '2101081811' --item_desc like '%100E36%' 
 
-- like zoro pns
select their_item_id,item_id[SIMG],item_desc,customer_id,x.inv_mast_uid
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where their_item_id like 'G2074287%'

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
where item_desc like 'DW6X%' and customer_id = 55932

select their_item_id,item_id[SIMG],item_desc,cast(customer_id as int)customer_id
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where item_desc like '331%' and customer_id = 55932


select x.their_item_id,m.item_id, m.item_desc, m.extended_desc,x.customer_id,m.inv_mast_uid,ild.item_list_dtl_uid
from dbo.item_list_dtl ild
join dbo.inv_mast m
on ild.inv_mast_uid = m.inv_mast_uid and item_list_hdr_uid = 1 
join dbo.inv_xref x
on m.inv_mast_uid = x.inv_mast_uid
where customer_id = 55932 and item_id = '2101081811' -- their_item_id = 'G208091098'--
order by item_list_dtl_uid 

select *
from item_list_dtl
where item_list_hdr_uid = 1 and inv_mast_uid = 56203

select *
from dbo.item_list_dtl
where item_list_dtl_uid = 823

select *
from inv_xref
where their_item_id like 'G208311%'

select item_id, item_desc,extended_desc,class_id1,class_id2
from inv_mast
where item_desc like 'AOR224H%'

select inv_mast_uid
from dbo.item_list_dtl
where inv_mast_uid = 53791 and item_list_hdr_uid = 1