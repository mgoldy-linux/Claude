/*
	08/25/2021 - create a view for PTI part orders
	open orders parts only from PTI
	08/27/2021 - need to use CTE, to filter out nulls or blanks
	11/18/2021 - change product group source to inv_loc
	12/23/2021 - change location to shipping 
	01/13/2022 - add h.location_id to eliminate IPTCI parts
	01/14/2022 - remove assembly because filtering out too many parts
	06/23/2022 - update for the new item id
	07/25/2022 - temporary fix for remark parts
	09/05/2022 - add class id 1 & 5
*/
--use P21Play;
use P21;
/*
if OBJECT_ID ('Bar_Item_ID_PTI_Labels_VW', 'V') is not null
drop view Bar_Item_ID_PTI_Labels_VW;
go

create view [dbo].[Bar_Item_ID_PTI_Labels_VW] AS
*/
with getParts(select_item_id, item_desc,default_product_group,
	 inv_mast_uid, [M-UPC],item_ext_desc)
as
(
	select distinct m.item_id,m.item_desc,il.product_group_id,m.inv_mast_uid,
	case when product_group_id not like 'K%' then m.upc_or_ean_id
	else their_item_id
	end, m.extended_desc
	From inv_mast m
	join inv_loc il
	on m.inv_mast_uid = il.inv_mast_uid and m.class_id1 = 'PTI' and m.delete_flag = 'N'
	left join inv_xref  x
	on m.inv_mast_uid = x.inv_mast_uid
	where item_desc not like 'D-%'
),
getSupplierUPC(select_item_id, item_desc, default_product_group,
	 [M-UPC],[S-UPC],inv_mast_uid)
as
(
	select distinct select_item_id, item_desc, default_product_group,isnull([M-UPC],s.upc_code),ISNULL(s.upc_code,[M-UPC]),gp.inv_mast_uid
	from getParts gp
	join inventory_supplier s
	on gp.inv_mast_uid = s.inv_mast_uid
)
select select_item_id, item_desc,mu.legacy_item_description[ext_item_desc], default_product_group, 
case
	when [S-UPC] is null then [M-UPC]
	when [S-UPC] = '' then [M-UPC]
	else [M-UPC]
end [UPC]
from getSupplierUPC  supc
join inv_mast_ud mu
on supc.inv_mast_uid = mu.inv_mast_uid
go 
/*
grant select,update,references on object::Bar_Item_ID_PTI_Labels_VW to p21_application_role
grant select,update,references on object::Bar_Item_ID_PTI_Labels_VW to PxxiUser
grant select,update,references on object::Bar_Item_ID_PTI_Labels_VW to [PTIDOM\P21Users]
*/