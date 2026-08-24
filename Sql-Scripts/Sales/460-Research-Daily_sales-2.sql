select c.customer_name,c.customer_id,h.total_amount,(total_amount - shipping_cost)[profit]
from dbo.invoice_line l
join dbo.invoice_hdr h
on h.invoice_no = l.invoice_no
join dbo.customer c
on h.customer_id = c.customer_id
--where invoice_date between '2022-07-01' and '2022-09-30' and branch_id = 400 and sales_location_id = 460
--where invoice_date between '2022-10-01' and '2022-12-31' and branch_id = 400 and sales_location_id = 460
where invoice_date between '2023-05-01' and Getdate() and branch_id = 400 and sales_location_id = 460 and c.customer_id = 48052
--where invoice_date between '2023-04-01' and '2023-06-30' and branch_id = 400 and sales_location_id = 460
order by invoice_date

select shipping_cost,*
from invoice_hdr
where invoice_date between '2023-05-01' and Getdate() and branch_id = 400 and sales_location_id = 460 and customer_id = 48306

select cogs_amount,*
from invoice_line 
where invoice_no = '3364928'

select c.customer_name,c.customer_id,sum(h.total_amount)[CurMonthSales],sum(total_amount - shipping_cost)[profit]
from dbo.invoice_line l
join dbo.invoice_hdr h
on h.invoice_no = l.invoice_no
join dbo.customer c
on h.customer_id = c.customer_id
where invoice_date between '2023-5-01' and Getdate() and c.customer_id = 48073
group by customer_name,c.customer_id

select c.customer_name,c.customer_id,sum(h.total_amount)[CurMonthSales],sum(total_amount - shipping_cost)[CurProfit]
from dbo.invoice_hdr h
join dbo.customer c
on h.customer_id = c.customer_id
where invoice_date between '2023-05-01' and Getdate() and c.customer_id = 48052
group by customer_name,c.customer_id