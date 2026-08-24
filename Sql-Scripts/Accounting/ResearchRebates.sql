select description,calculation_value1--,price_page_uid, price_page_type_cd
from price_page
--where description = 'PTI-DIST-B4'
order by price_page_type_cd

select *
from invoice_hdr
where invoice_no = '3108716'

select *
from oe_hdr
where order_no = 1136996

select *
from invoice_line
where invoice_no = '3108716'

select *
from oe_line
where order_no = 1136996


select price1,price9
from inv_mast
where inv_mast_uid = 33330

select *
from price_library