select their_item_id[Fastenal ID],item_id[SIMG]
from dbo.inv_xref x
join inv_mast  m
on x.inv_mast_uid = m.inv_mast_uid
where customer_id = 16425 and x.delete_flag = 'N' and m.delete_flag = 'N'
order by SIMG

select item_id[SIMG-846],item_desc
from item_list_dtl ed
join inv_mast  m
on ed.inv_mast_uid = m.inv_mast_uid
where  item_list_hdr_uid = 2
order by [SIMG-846]