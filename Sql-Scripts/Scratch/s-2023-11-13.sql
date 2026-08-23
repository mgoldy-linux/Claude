select top 5 *
from p21_view_GetOpenOrders h
join p21_view_GetOpenOrdersDetail l
on h.order_no = l.order_no
where item_id = '2101001818'

select *
from dWeekly_Open_Orders_VW
where order_no = '1558949'

select cogs_amount, item_id,*
from invoice_line
where invoice_no = '460149308' and line_no =1 

select cogs_amount, item_id,*
from invoice_line
where invoice_no = '3228964' and line_no = 9 
