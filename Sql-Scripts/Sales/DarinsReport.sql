with getinvoices 
as
(
	select c.customer_name,h.customer_id,l.item_id,Sum(qty_shipped)[qty_shipped],sum(extended_price)[P],sum(cogs_amount)[c]
	from invoice_line l
	join invoice_hdr h
	on l.invoice_no = h.invoice_no
	join oe_hdr oh
	on h.order_no = oh.order_no 
	join customer c
	on c.customer_id = h.customer_id and c.credit_status != 'INACTIVE'
	where h.sales_location_id = 300 and h.order_date between '2019-01-01' and getdate() and extended_price > 0 
	group by c.customer_name,h.customer_id,l.item_id
	)
	select customer_name,customer_id,item_id, qty_shipped,P,c,(1-c/P)*100[%Profit]
	from getinvoices
	where item_id != 'BillBack' and customer_name not like '%CLOSED%'
	order by customer_name