use p21;

select case 
when source_code_no = 706 then 'OE'
when source_code_no = 707 then 'Import'
when source_code_no = 708 then 'EDI'
when source_code_no = 709 then 'Quote'
when source_code_no = 3067 then 'Test Order'
else 'Unknown'
end[Order_Source],count(distinct h.order_no)[NumberOfOrders],sum(extended_price)[Total],location_id
from oe_hdr h
join oe_line l
on h.order_no = l.order_no
where year(h.date_created) = year(getdate()) and month(h.date_created) = month(getdate()) and day(h.date_created) = day(getdate()) and h.delete_flag = 'N' and projected_order = 'N' and h.cancel_flag = 'N' 
and other_charge = 'N' and l.delete_flag = 'N' and l.cancel_flag = 'N'
group by source_code_no,location_id

/*
select*
from email_log 
where transaction_type = 'ORDER ACKNOWLEDGEMENT'and year(date_created) = year(getdate()) and month(date_created) = month(getdate()) and day(date_created) = day(getdate())



select  distinct source_code_no,code_description
from dbo.oe_hdr h
join dbo.code_p21 cp
on h.source_code_no = cp.code_no


select *
from code_p21
where code_no = 708

select *
from oe_hdr
where source_code_no = 3067
*/