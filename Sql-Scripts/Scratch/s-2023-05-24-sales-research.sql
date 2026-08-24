select * from d_Open_Quote_Summary where SalesRepName like '%10659%'
select * from d_Open_Orders_Summary where SalesRepName like '%10659%'

select * from d_Open_Quote_Summary where SalesRepName like '%18353%'
select * from d_Open_Orders_Summary where SalesRepName like '%18353%'

select distinct salesrep_id
from oe_hdr_salesrep
where date_created > '2023-05-24'
order by salesrep_id

select *
from oe_hdr_salesrep 
where date_created > '2023-05-24' and salesrep_id = 1024


select order_no,source_id,po_no
from oe_hdr
where  date_created > '2023-05-10' and source_code_no = 709 and source_id = 1457505

select oe_hdr_uid, *
from oe_hdr
where order_no in (1457505,1457935)

select *
from dbo.quote_hdr
where oe_hdr_uid = 454705

select order_no, source_id, source_code_no
from oe_hdr
where order_no = source_id