--test queries for Last-3yrs-shippedt.psi

select SUM(qty_shipped)[Qty-Sold-2020]
from p21_sales_history_report_view
where item_id = '2101011825' and order_date between '2020-01-01' and '2020-12-31'

select SUM(qty_shipped)[Qty-Sold-2021]
from p21_sales_history_report_view
where item_id = '2101011825' and order_date between '2021-01-01' and '2021-12-31'

select SUM(qty_shipped)[Qty-Sold-2022]
from p21_sales_history_report_view
where item_id = '2101011825' and order_date between '2022-01-01' and '2022-12-31'