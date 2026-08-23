use P21Local2020;
--use P21Play;
--use P21;
/*
if OBJECT_ID ('_CR_PT_Items_Bin_VW', 'V') is not null
drop view _CR_PT_Items_Bin_VW;
go

create view [dbo].[_CR_PT_Items_Bin_VW] AS
*/
select cast(p.pick_ticket_no as varchar)[pick_ticket_no],p.order_no, cast(d.line_number as varchar)[line_number],m.item_id,m.item_desc,d.qty_to_pick,primary_bin,d.unit_of_measure,qty_on_hand,o.assembly,parent_oe_line_uid,oe_line_uid,m.inv_mast_uid,b.bin,b.quantity
from oe_pick_ticket p
join oe_pick_ticket_detail d
on p.pick_ticket_no = d.pick_ticket_no
join inv_mast m
on d.inv_mast_uid = m.inv_mast_uid
join inv_loc l
on l.inv_mast_uid = m.inv_mast_uid and p.location_id = l.location_id and  other_charge_item = 'N'
join oe_line o
on d.oe_line_no = o.line_no and d.inv_mast_uid = o.inv_mast_uid AND p.order_no = o.order_no
left join p21_view_pick_ticket_bins b 
on  d.inv_mast_uid = b.inv_mast_uid and l.location_id = b.location_id
where  p.date_created > DATEADD(DAY,-40,GetDate()) and m.delete_flag = 'N' and o.cancel_flag = 'N' and o.delete_flag = 'N'

/*
go 

grant select,update,references on object::_CR_PT_Items_Bin_VW to admin
grant select,update,references on object::_CR_PT_Items_Bin_VW to crystal
grant select,update,references on object::_CR_PT_Items_Bin_VW to [PTIDOM\P21Users]
*/