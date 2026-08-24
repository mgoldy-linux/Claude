/*
	(@ls_CompanyID VARCHAR(8),@ls_BeginInvoiceNo VARCHAR(10),@ls_EndInvoiceNo VARCHAR(10),@ls_BeginBranchID VARCHAR(8),@ls_EndBranchID VARCHAR(8),@li_BeginCustomerID	INTEGER,@li_EndCustomerID INTEGER,@ls_BeginZipCode VARCHAR(8),@ls_EndZipCode VARCHAR(8),@ls_BeginRoute VARCHAR(8),@ls_EndRoute VARCHAR(8),@li_BeginShipTo INTEGER
,@li_EndShipTo INTEGER,@ldt_BeginDate DATETIME,@ldt_EndDate DATETIME,@li_BeginPickTicketNo INTEGER,@li_EndPickTicketNo INTEGER,@li_BeginInvBatchNo INTEGER,@li_EndInvBatchNo INTEGER)
*/

select *
from p21_fnt_packing_list_line('1','3160868','3160868','200','200',10083,10083,' ','ZZZZZZZZZZ',' ','ZZZZZ',0,999999999,'2021-01-01 00:00:00','2021-11-26 23:59:59',2166283,2166283,0,9999) 

select *
from invoice_line
where invoice_no = '3160868'

select *
from p21_invoice_amt_remaining_view
where invoice_reference_no = '3160868'

select *
from oe_line_schedule
where order_no = 1158016