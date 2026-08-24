/*
	03/23/2020 - email from Melissa -Mark is this something you could change?  It was put in as an order but should have been a quote.
Order 1049496

*/

Select projected_order
from oe_hdr
where order_no = 1049496

update oe_hdr
set projected_order = 'Y'
where order_no = 1049496

Select projected_order
from oe_hdr
where order_no = 1049496