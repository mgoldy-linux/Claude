/*
	03/02/2020 - tables & view related to quotes
*/

select  *
from oe_hdr
where order_no = 1044278


select *
from quote_hdr
where oe_hdr_uid = 34317

select *
from quote_line
where oe_line_uid = 103672 or oe_line_uid = 103674 or oe_line_uid = 103675

select oe_line_uid
from oe_line
where order_no = 1034384

--has the most data about the quote
select *
from p21_quotation_view
where order_no = 1034384

select *
from p21_view_quote_hdr

select *
from p21_view_quote_line