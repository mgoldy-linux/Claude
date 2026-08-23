/*
	10/05/2021 - Yes, but can you also include Sale price? 
*/

Use P21;

with getSales(item_id,item_desc,qty_shipped,salesprice,totalsales,cost)
as
(
	select item_id,item_desc,sum(qty_shipped),extended_price,sum(qty_shipped*extended_price),sum(qty_shipped*cogs_amount)
	from invoice_hdr h
	join invoice_line il
	on h.invoice_no = il.invoice_no
	where Year(invoice_date) =  2021 and il.item_id between 'D-000000' and 'D-999999'
	group by il.item_id,item_desc,extended_price
),
removeZero(item_id,item_desc,qty_shipped,salesprice,totalsales,cost)
as
(
	select item_id,item_desc,qty_shipped,salesprice,
	case when totalsales = 0 then 1
	else totalsales
	end,cost
	from getSales

)
select item_id,item_desc,qty_shipped,salesprice,totalsales,cost,(1-cost/totalsales)*100[%Profit]
from removeZero
order by item_id
