use P21Play;

-- find invoices by customer name, avoid EDI customers
/*
select Top 10 * 
from invoice_hdr
where period = 5 and year_for_period = 2020 and bill2_name like 'W%'
*/

-- find invoices that will print double lines, avoid EDI customers
select distinct l.invoice_no, h.order_no,qty_shipped, item_id, item_desc, customer_part_number,other_charge_item,product_group_id,bill2_name,branch_id
from invoice_line l
join invoice_hdr h
on l.invoice_no = h.invoice_no
where other_charge_item = 'Y' and l.invoice_no like '300%' and h.order_no like '100%'
order by invoice_no

