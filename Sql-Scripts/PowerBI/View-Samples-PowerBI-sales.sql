select top 100 *
from dbo.p21_sales_history_view
order by invoice_date desc

select top 100 *
from dbo.p21_item_view

select top 100 *
from dbo.p21_customer_view

select top 100 *
from  dbo.p21_order_view
order by date_last_modified desc

select *
from location