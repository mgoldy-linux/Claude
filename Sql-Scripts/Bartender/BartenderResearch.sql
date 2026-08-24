select * from Bar_Item_ID_PTI_Labels_VW
select * from BAR_Dodge_Labels_VW
select * from Bar_PTI_Labels_VW
select * from Bar_PT_PTI_Labels_VW where pick_ticket_no = 2186705

select *
from oe_pick_ticket_detail
where pick_ticket_no = 2151265

select *
from oe_line 
where order_no = 1183928
order by line_no

select *
from oe_pick_ticket
where pick_ticket_no = 2151265