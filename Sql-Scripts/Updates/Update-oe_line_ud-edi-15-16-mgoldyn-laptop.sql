select edi_field_15, edi_field_16, *
from oe_line_ud
--where order_no in (1584842,1584767,1584344)  -- first time
where order_no in (1587978,1587976,1587835,1587723,1587354,1587353,1587085,1586866,1586271,1585893,1585573,1585547,1585546,1585545,1585544,1585543,1585503,1585247,1585207,1585186) -- 2nd set

update dbo.oe_line_ud
set edi_field_16 = 1, edi_field_15 = null
where order_no = 1584842

update dbo.oe_line_ud
set edi_field_16 = 1, edi_field_15 = null
where order_no = 1584767

update dbo.oe_line_ud
set edi_field_16 = 1, edi_field_15 = null
where order_no = 1584344

select edi_field_15, edi_field_16, *
from oe_line_ud
where order_no in (1584842,1584767,1584344)
