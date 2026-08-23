-- 07/05/2022 - new lables most solve companies
-- 11/14/2022 - remove NOTEPL per Donna Havarnek class_id2 = 'EPL' and, remove UPC
use P21Play;
--use P21;

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
end [class_id1], m.default_product_group,default_price_family_uid,item_desc
from inv_mast m
where (default_product_group not in ('OTHERCHG','D1') and m.delete_flag = 'N' ) or (default_product_group = 'GS' and m.delete_flag = 'N') or (default_product_group like 'K%' and m.delete_flag = 'N') or (default_product_group = 'N1' and m.delete_flag = 'N') or  (default_product_group is null and m.delete_flag = 'N') and item_desc not like 'T%'
--order by class_id1
/*
go 

grant select,update,references on object::Bar_Solve_Items_VW to p21_application_role
grant select,update,references on object::Bar_Solve_Items_VW to PxxiUser
grant select,update,references on object::Bar_Solve_Items_VW to [PTIDOM\P21Users]
*/