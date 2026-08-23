Select ship2_state,branch_id,branch_description,sales_location_id,source_location_name,customer_name,invoice_no,order_no,FORMAT(invoice_date,'yyyy-MM-dd')[invoice_date],customer_id,bill2_name,period,year_for_period,invoice_type,total_amount,
qty_shipped,item_id,item_desc,unit_price, extended_price,cogs_amount,product_group_desc
from p21_sales_history_view
where ship2_state in ('ID','MT','OR','WA')


