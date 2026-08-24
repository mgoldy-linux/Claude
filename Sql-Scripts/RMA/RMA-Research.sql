select distinct order_no[RMA/Order No],v.date_created,customer_id,open_total_value, lost_sales_desc,location_id
from p21_view_open_rma_report r
join p21_view_lost_sales_transaction v
on r.order_no = v.transaction_no
join lost_sales ls
on ls.lost_sales_uid = v.lost_sales_uid
where qty_open > 0
order by date_created

select *
from lost_sales

select transaction_no,date_created,*
from p21_view_lost_sales_transaction v


select *
from oe_hdr_rma

select *
from p21_view_rma_receipt_hdr

select *
from p21_view_open_rma_report
where qty_open > 0
order by order_date desc

select *
from p21_view_support_sql_serviceorder_rma_receipt_hdr

select transaction_no,date_created
from p21_view_lost_sales_transaction v

select *
from rma_receipt_hdr

select *
from rma_receipt_line 
where rma_receipt_hdr_uid =  '4001'

select *
from p21_view_oe_hdr_rma

select *
from p21_view_oe_line_rma

select *
from p21_view_open_rma_report