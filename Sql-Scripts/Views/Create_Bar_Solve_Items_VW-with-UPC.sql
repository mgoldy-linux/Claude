-- Need to figure out how filter out items that have UPC & Blank
--use P21Play;
--use P21;
Use P21Sand;

/*
if OBJECT_ID ('Bar_Solve_Items_VW', 'V') is not null
drop view Bar_Solve_Items_VW;
go

create view [dbo].[Bar_Solve_Items_VW] AS
*/

select distinct item_desc[legacy_item_id],item_id,
case
	when class_id1 = 'PTI' and default_price_family_uid = 9 then 'GoldSpec'
	when class_id1 = 'PTI' and default_price_family_uid = 11 then 'NSK'
else class_id1
end [class_id1], m.default_product_group,default_price_family_uid,item_desc,(isu.upc_code + convert(varchar(1),isu.check_digit))[UPC]
from dbo.inv_mast m
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid
where (default_product_group not in ('OTHERCHG','D1') and m.delete_flag = 'N' ) or (default_product_group = 'GS' and m.delete_flag = 'N') or (default_product_group like 'K%' and m.delete_flag = 'N') or (default_product_group = 'N1' and m.delete_flag = 'N') or  (default_product_group is null and m.delete_flag = 'N') and item_desc not like 'T%' and isu.delete_flag = 'N'
order by item_id 
/*
go 

grant select,update,references on object::Bar_Solve_Items_VW to p21_application_role
grant select,update,references on object::Bar_Solve_Items_VW to PxxiUser
grant select,update,references on object::Bar_Solve_Items_VW to [PTIDOM\P21Users]
*/