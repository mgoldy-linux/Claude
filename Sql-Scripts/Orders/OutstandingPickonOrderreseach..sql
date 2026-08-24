-- Go to System/ System Admin/ System/ Rebuild Transactions for 'orders'
-- Then rebuid inventory, might need to rebuilt inventory multiple times
select *
from oe_hdr
where order_no in (1304652,1304733)

select *
from oe_pick_ticket
where order_no in (1304652,1304733)

select inv_mast_uid,*
from oe_line 
where order_no in (1304652,1304733)
order by order_no, line_no

select *
from oe_pick_ticket_detail
where pick_ticket_no in (2242569,2242615,2242623)

select item_id
from inv_mast
where inv_mast_uid = 29477