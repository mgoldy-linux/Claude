select default_price_family_uid,*
from inv_mast 
where default_product_group like 'N%'

select *
from price_family


select item_desc,item_id,class_id1
from inv_mast
where default_price_family_uid = 11

select *
from Bar_Solve_Items_VW
where class_id1 = 'GoldSpec'

select distinct item_desc[legacy_item_id],item_id,
case
	when class_id1 = 'PTI' and default_price_family_uid = 9 then 'GoldSpec'
	when class_id1 = 'PTI' and default_price_family_uid = 11 then 'NSK'
else class_id1
end [class_id1], m.default_product_group,default_price_family_uid,item_desc
from inv_mast m
where (default_product_group not in ('OTHERCHG','D1') and m.delete_flag = 'N' ) or (default_product_group = 'GS' and m.delete_flag = 'N') or (default_product_group like 'K%' and m.delete_flag = 'N') or (default_product_group = 'N1' and m.delete_flag = 'N') or  (default_product_group is null and m.delete_flag = 'N') and item_desc not like 'T%

select *
from Bar_NSK_Pick_Ticket_15_Labels_VW