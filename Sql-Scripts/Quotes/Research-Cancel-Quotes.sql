-- test canceling a quote
-- quote hdr
select *
from quote_hdr
where oe_hdr_uid = 1461

update quote_hdr
set complete_flag = 'y'
where oe_hdr_uid = 1461

select *
from quote_hdr
where oe_hdr_uid = 1461

-- quote line
select *
from quote_line
where oe_line_uid in (3737,3739,3740,3759,3760,3761)

update quote_line
set line_complete_flag = 'Y'
where oe_line_uid in (3737,3739,3740,3759,3760,3761)

select *
from quote_line
where oe_line_uid in (3737,3739,3740,3759,3760,3761)
-- oe_hdr
select cancel_flag, completed
from oe_hdr
where order_no = 1001463

update oe_hdr
set cancel_flag = 'Y', completed = 'Y'
where order_no = 1001463

select cancel_flag, completed
from oe_hdr
where order_no = 1001463

select *
from oe_line
where order_no = 1001463

update oe_line
set complete = 'Y'
where order_no = 1001463

select *
from oe_line
where order_no = 1001463

select top 6 * --select max(lost_sales_transaction_uid)[max]  --
from lost_sales_transaction 
where transaction_no = 1001463

set IDENTITY_INSERT lost_sales_transaction ON
insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6486,13,'N',2487,1001463,1,25,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')

insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6487,13,'N',2487,1001463,2,25,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')

insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6488,13,'N',2487,1001463,3,25,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')

insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6489,13,'N',2487,1001463,4,50,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')

insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6490,13,'N',2487,1001463,5,50,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')

insert into lost_sales_transaction (lost_sales_transaction_uid,lost_sales_uid,affect_usage,transaction_code_no,transaction_no,line_no,sku_qty_change,usage_processed_flag,date_created,created_by,date_last_modified,last_maintained_by)
values (6491,13,'N',2487,1001463,6,50,'N',Getdate(),'mgoldy-sql',GetDate(),'mgoldy-sql')

set IDENTITY_INSERT lost_sales_transaction OFF