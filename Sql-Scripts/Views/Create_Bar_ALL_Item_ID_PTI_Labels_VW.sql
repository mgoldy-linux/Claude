/*
10/17/22 for ROSS -WWMS
*/
use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_ALL_Item_ID_PTI_Labels_VW', 'V') is not null
drop view Bar_ALL_Item_ID_PTI_Labels_VW;
go

create view [dbo].[Bar_ALL_Item_ID_PTI_Labels_VW] AS
*/
	select distinct item_id, item_desc,
	case
		when upc_or_ean_id is null and upc_code is not null then concat(upc_code , check_digit)
		 when upc_or_ean_id is not null and upc_code is null then upc_or_ean_id 
		 when upc_or_ean_id is not null and upc_code is not null then concat(upc_code , check_digit)
		 when upc_or_ean_id is null and upc_code is null then ''
	end[UPC],extended_desc
	from dbo.inv_mast m
	join dbo.inventory_supplier s
	on m.inv_mast_uid = s.inv_mast_uid
	where m.delete_flag = 'N' and class_id1 = 'PTI' --and item_id = '2101006640'
go 
/*
grant select on object::Bar_ALL_Item_ID_PTI_Labels_VW to p21_application_role
grant select on object::Bar_ALL_Item_ID_PTI_Labels_VW to PxxiUser
grant select on object::Bar_ALL_Item_ID_PTI_Labels_VW to [PTIDOM\P21Users]
*/