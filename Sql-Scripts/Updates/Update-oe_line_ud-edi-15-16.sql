Use p21;

select edi_field_15, edi_field_16, *
from oe_line_ud
where order_no in (1584842,1584767,1584344)

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
