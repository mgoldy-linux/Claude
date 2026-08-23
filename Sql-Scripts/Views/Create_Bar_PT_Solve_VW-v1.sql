use P21Play;
--use P21;
/*
if OBJECT_ID ('Bar_PT_Solve_VW', 'V') is not null
drop view Bar_PT_Solve_VW;
go

create view [dbo].[Bar_PT_Solve_VW] AS
*/

select opt.pick_ticket_no,opt.order_no,opd.line_number,m.item_id,m.item_desc,
case
	when class_id1 = 'PTI' and default_price_family_uid = 9 then 'GoldSpec'
	when class_id1 = 'PTI' and default_price_family_uid = 11 then 'NSK'
else class_id1
end [LogoBrand],default_product_group,pf.price_family_id
from dbo.oe_pick_ticket opt
join dbo.oe_pick_ticket_detail opd
on opt.pick_ticket_no = opd.pick_ticket_no
join dbo.inv_mast m
on opd.inv_mast_uid = m.inv_mast_uid
join dbo.price_family pf
on m.default_price_family_uid = pf.price_family_uid
join dbo.oe_line ol
on opt.order_no = ol.order_no and opd.inv_mast_uid = ol.inv_mast_uid AND opd.oe_line_no = ol.line_no
where opt.delete_flag = 'N' and location_id = 100 and ship_date is null and (default_product_group not in ('OTHERCHG','D1') OR m.default_product_group IS NULL) AND (ol.qty_on_pick_tickets <> 0) AND (opd.print_quantity <> 0) and m.delete_flag = 'N'
order by default_product_group
go 
/*
grant select on object::Bar_PT_Solve_VW to p21_application_role
grant select on object::Bar_PT_Solve_VW to PxxiUser
grant select on object::Bar_PT_Solve_VW to [PTIDOM\P21Users]
*/

