-- 06/27/23 - Timken by Pick-Ticket
-- 10/12/23 - add Po No and COO for pallet, 
--use P21Sand;
use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_Timken_Pick_Ticket_Labels_VW', 'V') is not null
drop view Bar_Timken_Pick_Ticket_Labels_VW;
go

create view [dbo].[Bar_Timken_Pick_Ticket_Labels_VW] AS
*/
select pth.pick_ticket_no,item_id[SIMG],item_desc[Marketplace Description],extended_desc[ext_item_desc],default_product_group,
case
	when upc_or_ean_id is null and upc_code is not null then concat(upc_code , check_digit)
	when upc_or_ean_id is not null and upc_code is null then upc_or_ean_id 
	when upc_or_ean_id is not null and upc_code is not null then concat(upc_code , check_digit)
	when upc_or_ean_id is null and upc_code is null then ''
end[UPC Code],po_no,
case
	when ist.country_of_origin = 'CN' then 'CHINA'
	when ist.country_of_origin = 'RY' then 'Assemble is U.S.A'
	when ist.country_of_origin = 'TW' then 'TAIWAN'
	else 'UNKNOWN'
end [COO], REPLACE(item_desc,'T-','')[Pallet_desc]
from dbo.oe_hdr h
join dbo.oe_pick_ticket pth
on h.order_no = pth.order_no
join dbo.oe_pick_ticket_detail d
on pth.pick_ticket_no = d.pick_ticket_no
join dbo.inv_mast m
on d.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier s
on m.inv_mast_uid = s.inv_mast_uid
join dbo.inventory_supplier_trade ist
on s.inventory_supplier_uid = ist.inventory_supplier_uid
where customer_id = 13443 and h.completed = 'N' and pth.delete_flag = 'N' and h.delete_flag = 'N' and pth.delete_flag = 'N'
/*
go 

grant select,update,references on object::Bar_Timken_Pick_Ticket_Labels_VW to p21_application_role
grant select,update,references on object::Bar_Timken_Pick_Ticket_Labels_VW to PxxiUser
grant select,update,references on object::Bar_Timken_Pick_Ticket_Labels_VW to [PTIDOM\P21Users]
*/