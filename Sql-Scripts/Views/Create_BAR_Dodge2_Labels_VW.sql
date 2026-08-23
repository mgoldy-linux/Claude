/*  
	07/07/2022 - new dodge label 2" * 1.25"
*/
use P21Play;
--use P21;

/*
if OBJECT_ID ('BAR_Dodge2_Labels_VW', 'V') is not null
drop view BAR_Dodge2_Labels_VW;
go

create view [dbo].[BAR_Dodge2_Labels_VW] AS
*/
select distinct item_id,po_no,substring(item_desc,3,6)[Dodge_PN],legacy_item_description,(s.upc_code + convert(varchar(1),s.check_digit))[UPC],Format(net_weight,'N2')[net_weight],ist.country_of_origin
from oe_hdr h
join oe_pick_ticket ph
on h.order_no = ph.order_no
join oe_pick_ticket_detail pl
on ph.pick_ticket_no = pl.pick_ticket_no
join inv_mast m
on m.inv_mast_uid = pl.inv_mast_uid
join inv_mast_ud mu
on mu.inv_mast_uid = m.inv_mast_uid
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join inventory_supplier_trade ist
on ist.inventory_supplier_uid = s.supplier_id
where  ph.delete_flag = 'N' and ph.invoice_no is null and default_product_group = 'D1'
order by po_no

/*
go 

grant select,update,references on object::BAR_Dodge2_Labels_VW to p21_application_role
grant select,update,references on object::BAR_Dodge2_Labels_VW to PxxiUser
grant select,update,references on object::BAR_Dodge2_Labels_VW to [PTIDOM\P21Users]
*/

/* first version 
select po_no,ph.pick_ticket_no,line_number, qty_requested,item_desc,legacy_item_description, upc_or_ean_id,net_weight,item_id,ist.country_of_origin
from oe_hdr h
join oe_pick_ticket ph
on h.order_no = ph.order_no
join oe_pick_ticket_detail pl
on ph.pick_ticket_no = pl.pick_ticket_no
join inv_mast m
on m.inv_mast_uid = pl.inv_mast_uid
join inv_mast_ud mu
on mu.inv_mast_uid = m.inv_mast_uid
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join inventory_supplier_trade ist
on ist.inventory_supplier_uid = s.supplier_id
where  ph.delete_flag = 'N' and ph.invoice_no is null and default_product_group = 'D1'
order by pl.pick_ticket_no,line_number

select *
from oe_pick_ticket
where pick_ticket_no = 2209074 

select *
from oe_pick_ticket_detail
where pick_ticket_no = 2209074 

select item_desc, extended_desc, upc_or_ean_id,net_weight,item_id
from inv_mast
where inv_mast_uid = 9889

select legacy_item_id, legacy_item_description
from inv_mast_ud
where inv_mast_uid = 9889

select upc_code,supplier_id
from inventory_supplier 
where inv_mast_uid = 9889

select country_of_origin
from inventory_supplier_trade
where inventory_supplier_uid = 16013

-- view 1
Select distinct item_id,
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
	(s.upc_code + convert(varchar(1),s.check_digit))[UPC],Format(net_weight,'N2')[net_weight],po_no
from oe_line ol
join inv_mast m
on ol.inv_mast_uid = m.inv_mast_uid
join inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join address a
on s.supplier_id = a.corp_address_id
join oe_hdr h
on ol.order_no = h.order_no
where m.item_desc like 'D-%' and ol.complete = 'N' and packing_basis != 'Hold'
order by po_no
*/