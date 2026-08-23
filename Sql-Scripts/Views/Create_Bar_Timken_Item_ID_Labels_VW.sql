--use P21sand;
--use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_Timken_Item_ID_Labels_VW', 'V') is not null
drop view Bar_Timken_Item_ID_Labels_VW;
go

create view [dbo].[Bar_Timken_Item_ID_Labels_VW] AS
*/
select item_id[SIMG],extended_desc[Marketplace Description],item_desc,
case
	when upc_or_ean_id is null and upc_code is not null then concat(upc_code , check_digit)
	when upc_or_ean_id is not null and upc_code is null then upc_or_ean_id 
	when upc_or_ean_id is not null and upc_code is not null then concat(upc_code , check_digit)
	when upc_or_ean_id is null and upc_code is null then ''
end[UPC Code]--,m.date_last_modified,s.date_last_modified,check_digit,s.last_maintained_by
from dbo.inv_mast m
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
where item_desc like 'T-%' and m.delete_flag = 'N' -- and item_id = '2101049135'
--order by s.date_last_modified desc
go
/*
grant select on object::Bar_Timken_Item_ID_Labels_VW to p21_application_role
grant select on object::Bar_Timken_Item_ID_Labels_VW to PxxiUser
grant select on object::Bar_Timken_Item_ID_Labels_VW to [PTIDOM\P21Users]
*/