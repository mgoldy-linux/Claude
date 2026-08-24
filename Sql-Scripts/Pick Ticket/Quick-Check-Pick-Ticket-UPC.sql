select distinct optd.oe_line_no,item_id, item_desc, upc_or_ean, isu.upc_code
from dbo.oe_pick_ticket_detail optd
join dbo.inv_mast m
on optd.inv_mast_uid = m.inv_mast_uid
join dbo.inventory_supplier isu
on isu.inv_mast_uid = m.inv_mast_uid
where pick_ticket_no = 2523174 


-- how to join inv_mast & inventory_supplier
select *
from inv_mast 
where item_id = '2101049031'

select *
from inventory_supplier
where inv_mast_uid = 49036

select *
from p21_view_oe_pick_ticket_detail
where pick_ticket_no = 2523174 

select *
from p21_view_asap_oe_pick_ticket
where pick_ticket_no = 2523174 