/*
		09/10/2021 - created for dodge labels, duplicated because multiple suppliers
		05/11/2022 - updated for the new dodge labels adding net weight & Po no
*/
--use P21Play;
use P21;

/*
if OBJECT_ID ('BAR_Dodge_Labels_VW', 'V') is not null
drop view BAR_Dodge_Labels_VW;
go

create view [dbo].[BAR_Dodge_Labels_VW] AS
*/


Select distinct
	substring(item_id,3,6)[Dodge_PN],item_desc, 
case
		when a.phys_country is null then 'US'
		when a.corp_address_id = 1 then 'US'
		when a.corp_address_id = 100 then 'US'
		when a.corp_address_id = 15823 then 'US'
		when a.corp_address_id = 15876 then 'BR'
		when a.corp_address_id = 15887 then 'US'
		when a.corp_address_id = 15894 then 'TW'
		when a.corp_address_id = 15915 then 'US'
		when a.corp_address_id = 15966 then 'TW'
		when a.corp_address_id = 16013 then 'CN'
		when a.corp_address_id = 16056 then 'US'
		when a.corp_address_id = 16110 then 'CN'
		else  a.phys_country
	End[COO],
	(s.upc_code + convert(varchar(1),s.check_digit))[UPC],Format(net_weight,'N2')[net_weight],ol.order_no,po_no
from oe_line ol
join inv_mast m
on ol.inv_mast_uid = m.inv_mast_uid
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join address a
on s.supplier_id = a.corp_address_id
join oe_hdr h
on ol.order_no = h.order_no
where m.item_id like 'D-%' and ol.complete = 'N' and packing_basis != 'Hold'

/*
go 

grant select,update,references on object::BAR_Dodge_Labels_VW to p21_application_role
grant select,update,references on object::BAR_Dodge_Labels_VW to PxxiUser
grant select,update,references on object::BAR_Dodge_Labels_VW to [PTIDOM\P21Users]
*/