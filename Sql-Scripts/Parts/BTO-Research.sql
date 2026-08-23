select distinct m.inv_mast_uid, item_id
from dbo.inv_mast_ud u
join dbo.inv_mast m
on u.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where bto_flag = 'Y'  and m.delete_flag = 'N' and l.delete_flag = 'N' and m.class_id2 = 'NOTEPL'
order by inv_mast_uid

select pc.price_library_uid,pc.row_status_flag, price_library_id 
from dbo.price_library_x_cust_x_cmpy pc
join dbo.price_library pl
on pc.price_library_uid = pl.price_library_uid
where customer_id = 10329

select *
from price_library
where price_library_uid > 184