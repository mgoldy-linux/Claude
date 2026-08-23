select *
from p21_assembly_view 
where item_id = '2101028081'

select *
from p21_view_production_components
where item_id = '2101028081'

select *
from p21_view_oe_hdr

select *
from p21_view_pick_ticket_components

select *
from p21_view_pickticket_components

select top 5 *
from p21_view_oe_pick_ticket

select count(*)[NumOfRec]
from p21_assembly_view v
where line_delete_flag = 'N'

select m.class_id1[brand],v.*
from dbo.p21_assembly_view v
join dbo.inv_mast m
on v.inv_mast_uid = m.inv_mast_uid
where line_delete_flag = 'N' and v.item_id = '2101028081'

