Use P21;

-- zoro
select inv_mast_uid, their_item_id,inv_xref_uid
from inv_xref
where customer_id = 55932 and delete_flag = 'N'
order by inv_mast_uid


-- fastenal
select inv_mast_uid, their_item_id,inv_xref_uid
from inv_xref
where customer_id = 16425 and delete_flag = 'N'
order by inv_mast_uid
