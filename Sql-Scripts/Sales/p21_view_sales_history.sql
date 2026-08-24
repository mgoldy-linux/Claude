-- day behind, need setup variable base on weekday

select *
from p21_sales_history_view
where year(order_date) = year(getdate()) and month(order_date) =  month(getdate()) and day(order_date) = 19