select order_date,l.customer_part_number,qty_ordered,h.order_no
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where customer_id = 13704 and order_date between '2019-01-01' and getdate() and h.delete_flag = 'N' and customer_part_number = '39H240031' and projected_order = 'N'

select item_id,qty_shipped,extended_price,cogs_amount/*,(1-cogs_amount/extended_price)*100[%Profit]*/,*
from invoice_line 
where invoice_no = '3016113'

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
	on c.customer_id = h.customer_id
	where h.sales_location_id = 300 and h.order_date between '2019-01-01' and getdate() and extended_price > 0 
	group by c.customer_name,h.customer_id,l.item_id
	)
	select customer_name,item_id, qty_shipped,P,c,(1-c/P)*100[%Profit]
	from getinvoices
	where item_id != 'BillBack'
	order by customer_name

select l.item_id,qty_shipped,extended_price,cogs_amount,l.invoice_no,h.order_no/*,(1-cogs_amount/extended_price)*100[%Profit]*/
from invoice_line l
join invoice_hdr h
on l.invoice_no = h.invoice_no
join inv_mast m
on l.inv_mast_uid = m.inv_mast_uid --and m.class_id2 = 'EPL'
where customer_id = 13704 and order_date between '2019-01-01' and getdate()


select *
from inv_mast
where item_id = 'BILLBACK'

select *
from invoice_hdr
where customer_id = 10323

select rma_flag
from oe_hdr
where order_no = 1021775
