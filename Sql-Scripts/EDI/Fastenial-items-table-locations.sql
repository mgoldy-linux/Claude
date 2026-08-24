-- EDI Fastenal translation table
select mapper_trans_value[fastenal-PN],mapper_trans_key[item_id], item_desc
from p21_mapper_translation_table mt
join inv_mast m
on mt.mapper_trans_key = m.item_id
where table_name = 'FASTENAL_ITEMS' 
order by item_id

-- customer cross reference table
select their_item_id[fastenal-PN], item_id, item_desc, default_product_group
from inv_xref x
join inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
where customer_id = 16425 and m.delete_flag = 'N' and x.delete_flag = 'N' --and item_id = '2101053887'
order by item_id

-- 846 table
select their_item_id[fastenal-PN],item_id, item_desc,m.inv_mast_uid
from item_list_dtl ild
join inv_mast m
on ild.inv_mast_uid = m.inv_mast_uid
join inv_xref x
on m.inv_mast_uid = x.inv_xref_uid
where item_list_hdr_uid = 2 and item_id = '2101053887'
order by item_id

-- unique records
select distinct their_item_id
from item_list_dtl ild
join inv_mast m
on ild.inv_mast_uid = m.inv_mast_uid
join inv_xref x
on m.inv_mast_uid = x.inv_xref_uid
where item_list_hdr_uid = 2
order by their_item_id

-- all fastenal transactions
select *
from p21_mapper_translation_table mt
where table_name = 'FASTENAL_ITEMS' 

-- location
select their_item_id[fastenal-PN], item_id, item_desc, default_product_group,l.location_id,qty_on_hand
from dbo.inv_xref x
join dbo.inv_mast m
on x.inv_mast_uid = m.inv_mast_uid
join dbo.inv_loc l
on m.inv_mast_uid = l.inv_mast_uid
where customer_id = 16425 and m.delete_flag = 'N' and x.delete_flag = 'N' and item_id = '2101053887'
order by item_id
