-- Jeremy called this a sales commision report
use P21;

select salesrep_first_name, salesrep_last_name,salesrep_id,customer_name,customer_id,bill2_name,invoice_no,order_no,FORMAT(invoice_date,'yyyy-MM-dd')[invoice_date],po_no,format(ship_date,'yyyy-MM-dd')[ship_date],freight,total_amount,amount_paid,terms_id,branch_id,sales_location_id,qty_shipped,
unit_of_measure,item_id,item_desc,unit_price,extended_price,cogs_amount,line_no,sales_cost,other_cost,format(order_date,'yyyy-MM-dd')[order_date],rma_flag,taker,sales_location_name,period,year_for_period
from p21_sales_history_view
--where branch_id = 400 and order_date between '2022-07-01' and '2022-09-30' and sales_location_id = 460 
--where branch_id = 400 and order_date between '2022-10-01' and '2022-12-31' and sales_location_id = 460 
where branch_id = 400 and order_date between '2023-01-01' and '2023-03-31' and sales_location_id = 460 
