use P21Sand;

select distinct il.*
from oe_line ol
left join invoice_line il
on ol.line_no = il.oe_line_number and il.order_no = ol.order_no
where ol.date_created > '2024-03-01'
order by order_no

select il.*
from invoice_line il
left join oe_line ol
on ol.line_no = il.oe_line_number and il.order_no = ol.order_no
where  ol.date_created > '2024-03-01' --and  ol.order_no = 1142207 --
order by order_no

select oe_line_number, *
from invoice_line il
left join oe_line ol
on ol.line_no = il.oe_line_number and il.order_no = ol.order_no
where ol.order_no = '1142207'
order by il.oe_line_number

select delete_flag,cancel_flag,*
from oe_line il
where order_no = '1142207' and delete_flag = 'N' and (disposition != 'C' or disposition is  null)

select order_no,*
from invoice_line
where invoice_no in ('3515399','3510024','3508790','3510107')