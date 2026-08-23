-- common between 846 & xref
with getXML846 
as
(
select ild.inv_mast_uid[uid846],item_id[SIMG],item_desc
from item_list_dtl ild
join inv_mast m
on ild.inv_mast_uid = m.inv_mast_uid
where item_list_hdr_uid = 1 and m.delete_flag = 'N'
),
getXref
as
(
select inv_mast_uid,their_item_id[zoro-pn]
from inv_xref
where customer_id = 55932 and delete_flag = 'N'
)
select *
from getXML846 g1
join getXref gx
on g1.uid846 = gx.inv_mast_uid
order by inv_mast_uid

with getXML846 
as
(
select ild.inv_mast_uid[uid846],item_id[SIMG],item_desc
from item_list_dtl ild
join inv_mast m
on ild.inv_mast_uid = m.inv_mast_uid
where item_list_hdr_uid = 1 and m.delete_flag = 'N'
),
getXref
as
(
select inv_mast_uid,their_item_id[zoro-pn]
from inv_xref
where customer_id = 55932 and delete_flag = 'N'
)
select g1.uid846,gx.inv_mast_uid, m2.item_desc,[zoro-pn],item_id
from getXref gx
left join  getXML846 g1
on g1.uid846 = gx.inv_mast_uid
join inv_mast m2
on gx.inv_mast_uid = m2.inv_mast_uid
where g1.uid846 is null
order by gx.inv_mast_uid