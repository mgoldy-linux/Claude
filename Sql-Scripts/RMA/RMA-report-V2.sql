-- 05/02/2022 first draft of RMA report
-- 06/20/2022 used in RMA-report-R1.xlsx
select transaction_no[RMA_No.],h.order_no,ls.lost_sales_desc[Reason],c.customer_name[Customer_Name],h.source_location_id[Source_Location_ID], format(v.date_created,'yyyy-MM-dd')[Create_Date]
from p21_view_lost_sales_transaction v
join lost_sales ls
on v.lost_sales_uid = ls.lost_sales_uid
join oe_hdr h
on v.transaction_no = h.order_no
join customer c
on h.customer_id = c.customer_id
where v.date_created > DATEADD(month,-18,getdate()) and order_no not in ('Quote','360D6188','BROOKS','S1706785','VERABL')
order by [Create_Date]


-- 2nd report wish from Rance email
select distinct order_no[RMA/Order No],format(r.order_date,'yyyy-MM-dd')[Order_Date],format(v.date_created,'yyyy-MM-dd')[RMA_Create_Date],customer_id,customer_name,cast(open_total_value as decimal(10,2))[Open Value], lost_sales_desc[Reason],location_id
from p21_view_open_rma_report r
join p21_view_lost_sales_transaction v
on r.order_no = v.transaction_no
join lost_sales ls
on ls.lost_sales_uid = v.lost_sales_uid
where qty_open > 0 --and order_no = '1150061'
order by RMA_Create_Date

-- 3rd Close RMA -- add the “Order Date”, “RMA Create Date” and “Reason” columns to the closed tab. didn't use
/*
select h.order_no[RMA_Number],format(h.order_date,'yyyy-MM-dd')[Order_Date], format(receipt_date,'yyyy-MM-dd')[RMA_receipt_date],h.customer_id,customer_name,h.location_id,note
from rma_receipt_hdr r
join oe_hdr h
on r.oe_hdr_uid = h.oe_hdr_uid
join customer c
on h.customer_id = c.customer_id
join oe_hdr_notepad n
on h.order_no = n.order_no
where receipt_date > DATEADD(DAY,-365,GetDate()) --and h.order_no = '1150061'
order by receipt_date desc
*/
-- Rev 3 add orginal order no, order date, invoice_no, invoice date 
select distinct r.order_no[RMA No],format(v.date_created,'yyyy-MM-dd')[RMA_Create_Date],ol.order_no,format(ol.date_created,'yyyy-MM-dd')[Order_Date],il.invoice_no,format(il.date_created,'yyyy-MM-dd')[Invoice_Date],r.customer_id,customer_name,cast(open_total_value as decimal(10,2))[Open Value], lost_sales_desc[Reason],location_id
from p21_view_open_rma_report r
join p21_view_lost_sales_transaction v
on r.order_no = v.transaction_no
join lost_sales ls
on ls.lost_sales_uid = v.lost_sales_uid
join dbo.oe_line_rma olr
on r.oe_line_uid = olr.oe_line_uid
join dbo.oe_line ol
on ol.oe_line_uid = olr.rma_linked_oe_line_uid
join dbo.invoice_line il
on il.invoice_line_uid = olr.invoice_line_uid
where qty_open > 0 
order by RMA_Create_Date

-- closed V3
select distinct h.order_no[RMA/Order No],format(h.order_date,'yyyy-MM-dd')[Order_Date], format(receipt_date,'yyyy-MM-dd')[RMA_Receipt_date],h.customer_id,customer_name,lost_sales_desc[Reason],h.location_id
from rma_receipt_hdr r
join oe_hdr h
on r.oe_hdr_uid = h.oe_hdr_uid
join customer c
on h.customer_id = c.customer_id
join lost_sales_transaction v
on h.order_no = v.transaction_no
join lost_sales ls
on ls.lost_sales_uid = v.lost_sales_uid

where receipt_date > DATEADD(DAY,-365,GetDate()) 
order by RMA_receipt_date desc
-- Closed RMAs

with get_close_rmas (RMA_No,RMA_Create_Date,Order_Date,il.invoice_no,Invoice_Date,customer_id,customer_name,Reason,location_id)
as
(
select distinct r.order_no,format(v.date_created,'yyyy-MM-dd'),ol.order_no,format(ol.date_created,'yyyy-MM-dd'),il.invoice_no,format(il.date_created,'yyyy-MM-dd'),r.customer_id,customer_name, lost_sales_desc,location_id)
from p21_view_open_rma_report r
join p21_view_lost_sales_transaction v
on r.order_no = v.transaction_no
join lost_sales ls
on ls.lost_sales_uid = v.lost_sales_uid
join dbo.oe_line_rma olr
on r.oe_line_uid = olr.oe_line_uid
join dbo.oe_line ol
on ol.oe_line_uid = olr.rma_linked_oe_line_uid
join dbo.invoice_line il
on il.invoice_line_uid = olr.invoice_line_uid
where qty_open = 0 and r.order_no = 1405037
)
select *
from get_close_rmas
--join dbo.rma_receipt_hdr rh
--on rh.invoice_no = il.invoice_no

order by RMA_Create_Date

select *
from p21_view_open_rma_report r
where order_no = 1405037

select *
from p21_view_lost_sales_transaction v
where transaction_no = 1405037

select *
from p21_view_rma_receipt_hdr

select *
from p21_view_rma_receipt_line
where rma_receipt_hdr_uid = 5971


select top 5 *
from rma_receipt_hdr
where receipt_no = 5971

select *
from oe_hdr_rma
where oe_hdr_uid = 402349

select top 5 *
from rma_receipt_line

select * 
from oe_line_rma
