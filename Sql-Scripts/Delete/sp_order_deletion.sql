-- might need to repair first 
-- exec p21_repair_sales_orders  

--exec p21_order_deletion 1,1453250,1453250,'2023-01-11',530,530,112993,112993,'Y','N','N','',706,'Y','Y','Y'


exec p21_repair_sales_orders 1410912 
exec p21_pick_ticket_cancel 2441191

exec p21_order_deletion 1,1410912,1410912,'2023-02-24',460,460,48073,48073,'Y','N','N','',706,'Y','Y','Y'

--exec sp_help  p21_order_deletion 1,

select cancel_flag,completed,*
from dbo.oe_hdr
where order_no = 1410912

update dbo.oe_hdr
set completed = NULL
where order_no = 1410912

select cancel_flag,delete_flag,completed,*
from dbo.oe_hdr
where order_no = 1410912

select cancel_flag,*
from dbo.oe_hdr
where order_no = 1410912

update dbo.oe_hdr
set cancel_flag = 'Y'
where order_no = 1410912

select cancel_flag,delete_flag,*
from dbo.oe_hdr
where order_no = 1410912

select *
from dbo.oe_pick_ticket
where order_no = 1410912

select distinct cancel_flag
from dbo.oe_hdr

select *
from oe_line
where order_no = 1410912


exec p21_rebuild_order_quantity 103300,460

select *
from inv_mast
where item_id = '2101111407'

select line_no,complete,delete_flag,cancel_flag,*
from oe_line
where order_no = 1410912

update oe_line
set cancel_flag = 'Y', complete = 'Y'
where order_no = 1410912 and line_no = 3

select line_no,complete,delete_flag,cancel_flag,*
from oe_line
where order_no = 1410912
