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
	08/05/2022 - add new item Id
*/
use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_Item_ID_IPTCI_Labels_VW', 'V') is not null
drop view Bar_Item_ID_IPTCI_Labels_VW;
go

create view [dbo].[Bar_Item_ID_IPTCI_Labels_VW] AS
*/
select distinct item_id[ScanItemID],legacy_item_id[Item_ID],legacy_item_description[Item_Desc],CONCAT(s.upc_code,s.check_digit)[UPC],country_of_origin[COO]
from inv_mast m
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join inventory_supplier_trade ist
on s.supplier_id = ist.inventory_supplier_uid
join inv_mast_ud mu
on m.inv_mast_uid = mu.inv_mast_uid
where class_id1 = 'IPTCI' and m.delete_flag = 'N'

go 
/*
grant select,update,references on object::Bar_Item_ID_IPTCI_Labels_VW to p21_application_role
grant select,update,references on object::Bar_Item_ID_IPTCI_Labels_VW to PxxiUser
grant select,update,references on object::Bar_Item_ID_IPTCI_Labels_VW to [PTIDOM\P21Users]
*/