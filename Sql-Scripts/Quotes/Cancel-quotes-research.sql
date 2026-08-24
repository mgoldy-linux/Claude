select order_no, oe_hdr_uid
from dbo.oe_hdr h
where location_id = 300 and projected_order = 'Y' and order_date < '2023-04-01' and cancel_flag = 'N' and completed = 'N' and delete_flag = 'N'

select *
from lost_sales_transaction 
where transaction_no = 1001463
select *
from quote_hdr
where oe_hdr_uid = 1461

select *
from quote_line
where oe_line_uid in (3737,3739,3740,3759,3760,3761)


select oe_hdr_uid
from oe_hdr
where order_no = 1003722

select oe_line_uid,*
from oe_line l
where order_no = 1003722
order by l.oe_line_uid


exec p21_df_complete_open_quotes

select location_id, projected_order, order_date,completed,delete_flag, lost_sales_uid, order_no,cancel_flag
from dbo.oe_hdr h
join dbo.lost_sales_transaction lst
on h.order_no = lst.transaction_no
where location_id = 300 and projected_order = 'Y' and order_date < '2023-04-01' and cancel_flag = 'N' and completed = 'N' and delete_flag = 'N'

select top 26 *
from lost_sales

select top 7*
from oe_hdr
where cancel_flag = 'Y'
order by date_last_modified desc

select top 8 *
from p21_view_opportunity_report
where cancel_flag = 'Y'

select top 7 *
from lost_sales_transaction
where transaction_no = 1420056