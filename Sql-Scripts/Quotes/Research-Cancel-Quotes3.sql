-- test canceling a quote   - reasom code grey out
-- quote hdr
select *
from quote_hdr
where oe_hdr_uid = 325795

update quote_hdr
set complete_flag = 'y'
where oe_hdr_uid = 325795

select *
from quote_hdr
where oe_hdr_uid = 325795

-- quote line
select *
from quote_line
where oe_line_uid in (1133399,1133400,1133401,1133402,1133403,1133404,1133405,1133406)

update quote_line
set line_complete_flag = 'Y'
where oe_line_uid = 10978

select *
from quote_line
where oe_line_uid = 1133399

-- oe_hdr
select * -- cancel_flag, completed,oe_hdr_uid,
from oe_hdr
where order_no = 1328349

update oe_hdr
set cancel_flag = 'Y', completed = 'Y'
where order_no = 1328349

select cancel_flag, completed
from oe_hdr
where order_no = 1328349

select oe_line_uid,qty_ordered
from oe_line
where order_no = 1328349

update oe_line
set complete = 'Y'
where order_no = 1328349

select *
from oe_line
where order_no = 1328349

select top 8* --select max(lost_sales_transaction_uid)[max]  --
from lost_sales_transaction 
where transaction_no = 1328349

set IDENTITY_INSERT lost_sales_transaction ON
insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6492,13,'N',2487,1328349,1,45,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')
set IDENTITY_INSERT lost_sales_transaction OFF