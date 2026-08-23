-- test canceling a quote   - reasom code grey out
-- quote hdr
select *
from quote_hdr
where oe_hdr_uid = 3711

update quote_hdr
set complete_flag = 'y'
where oe_hdr_uid = 3711

select *
from quote_hdr
where oe_hdr_uid = 3711

-- quote line
select *
from quote_line
where oe_line_uid = 10510

update quote_line
set line_complete_flag = 'Y'
where oe_line_uid = 10510

select *
from quote_line
where oe_line_uid = 10510

-- oe_hdr
select cancel_flag, completed
from oe_hdr
where order_no = 1003722

update oe_hdr
set cancel_flag = 'Y', completed = 'Y'
where order_no = 1003722

select cancel_flag, completed
from oe_hdr
where order_no = 1003722

select *
from oe_line
where order_no = 1003722

update oe_line
set complete = 'Y'
where order_no = 1003722

select *
from oe_line
where order_no = 1003722

select top 6 * --select max(lost_sales_transaction_uid)[max]  --
from lost_sales_transaction 
where transaction_no = 1003722

set IDENTITY_INSERT lost_sales_transaction ON
insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6492,13,'N',2487,1003722,1,45,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')
set IDENTITY_INSERT lost_sales_transaction OFF