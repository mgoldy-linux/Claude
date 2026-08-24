use P21;


select h.salesrep_name, h.salesrep_id,ship2_name[customer_name],customer_id,bill2_name,h.invoice_no,h.order_no,format(invoice_date,'yyyy-MM-dd')[invoice_date],po_no,format(ship_date,'yyyy-MM-dd')[ship_date],
total_amount,amount_paid,branch_id,sales_location_id,qty_shipped,unit_of_measure,item_id,item_desc,unit_price,extended_price,cogs_amount,line_no,sales_cost,other_cost,format(order_date,'yyyy-MM-dd')[order_date],period,year_for_period
from dbo.invoice_line l
join dbo.invoice_hdr h
on h.invoice_no = l.invoice_no
--where invoice_date between '2021-07-01' and '2021-09-30' and branch_id = 400 and sales_location_id = 460
--where invoice_date between '2021-10-01' and '2021-12-31' and branch_id = 400 and sales_location_id = 460
--where invoice_date between '2022-01-01' and '2022-03-31' and branch_id = 400 and sales_location_id = 460
where invoice_date between '2022-04-01' and '2022-06-30' and branch_id = 400 and sales_location_id = 460
/* alt version
with getCustomerIDs (Prev_ids)
as
(
select distinct customer_id
from p21_sales_history_view
where branch_id = 400 and order_date between '2022-07-01' and GetDate() and sales_location_id = 460 
)
select h.salesrep_name, h.salesrep_id,ship2_name[customer_name],customer_id,bill2_name,h.invoice_no,h.order_no,format(invoice_date,'yyyy-MM-dd')[invoice_date],po_no,format(ship_date,'yyyy-MM-dd')[ship_date],
total_amount,amount_paid,branch_id,sales_location_id,qty_shipped,unit_of_measure,item_id,item_desc,unit_price,extended_price,cogs_amount,line_no,sales_cost,other_cost,format(order_date,'yyyy-MM-dd')[order_date],period,year_for_period
from dbo.invoice_line l
join dbo.invoice_hdr h
on h.invoice_no = l.invoice_no
join getCustomerIds g
on g.Prev_ids = h.customer_id
where invoice_date between '2021-07-01' and '2021-09-30' and branch_id = 400
--where invoice_date between '2021-10-01' and '2021-12-31' and branch_id = 400
--where invoice_date between '2022-01-01' and '2022-03-31' and branch_id = 400
--where invoice_date between '2022-04-01' and '2022-06-30' and branch_id = 400
*/