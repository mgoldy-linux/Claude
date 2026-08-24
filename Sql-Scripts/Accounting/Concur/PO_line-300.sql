--use P21Sand;
use P21;

Select '300'[Record Type],item_id[External ID],line_no[Line Number],supplier_part_no[Supplier Part ID],''[Requested Delivery Date],''[Requested By],'Inventory 20020'[Expense Type],''[Account Code],pl.item_description[Description],cast(unit_quantity as decimal(5))[Quantity],base_ut_price[Unit Price],''[Tax],pricing_unit[UOM],''[Is Receipt Required],''[VAT Amount],''[VAT Rate],''[Amount without VAT],''[Future],''[Custom]
from dbo.po_line pl
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
join po_hdr ph
on pl.po_no = ph.po_no
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid and ph.supplier_id = isu.supplier_id
where pl.po_no in(4013889,4013545,4013872,4013104,4013423,4012437,4013417,4012410,4013416,4013510,4013016,4013137,4011341,4013508,4013566,4013351,4012998,4013248,4013389,4013004,4013053,4013566,4012729,4013015,4013508,4013014,4013105,4013045,4011435,4012766,4013053,4011341,4013280) and ph.delete_flag = 'N' and pl.delete_flag = 'N'


select inv_mast_uid,*
from po_line
where po_no = 4013889

select supplier_id
from po_hdr
where po_no = 4013889

select *
from inv_mast
where inv_mast_uid = 286

select supplier_id
from inventory_supplier 
where inv_mast_uid = 286

select Top 5 *
from dbo.po_line pl

-- final version add left join dbo.inventory_supplier isu 04/17/24 
Select '300'[Record Type],pl.po_line_uid[External ID],line_no[Line Number],supplier_part_no[Supplier Part ID],''[Requested Delivery Date],''[Requested By],''[Expense Type],'20020'[Account Code],item_id[Description],cast(unit_quantity as decimal(5))[Quantity],base_ut_price[Unit Price],''[Tax],pricing_unit[UOM],''[Is Receipt Required],''[VAT Amount],''[VAT Rate],''[Amount without VAT],''[Future],''[Custom]
from dbo.po_line pl
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
join po_hdr ph
on pl.po_no = ph.po_no
left join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid and ph.supplier_id = isu.supplier_id
where pl.po_no in(4013889,4013545,4013872,4013104,4013423,4012437,4013417,4012410,4013416,4013510,4013016,4013137,4011341,4013508,4013566,4013351,4012998,4013248,4013389,4013004,4013053,4013566,4012729,4013015,4013508,4013014,4013105,4013045,4011435,4012766,4013053,4011341,4013280) and ph.delete_flag = 'N' and pl.delete_flag = 'N'

-- single
Select '300'[Record Type],pl.po_line_uid[External ID],line_no[Line Number],supplier_part_no[Supplier Part ID],''[Requested Delivery Date],''[Requested By],''[Expense Type],'20020'[Account Code],item_id[Description],cast(unit_quantity as decimal(5))[Quantity],base_ut_price[Unit Price],''[Tax],pricing_unit[UOM],''[Is Receipt Required],''[VAT Amount],''[VAT Rate],''[Amount without VAT],''[Future],''[Custom]
from dbo.po_line pl
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
join po_hdr ph
on pl.po_no = ph.po_no
left join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid and ph.supplier_id = isu.supplier_id
where pl.po_no in(4012964) and ph.delete_flag = 'N' and pl.delete_flag = 'N'

select count (*)
from dbo.inventory_supplier
where supplier_part_no like '%,%'

Select '300'[Record Type],pl.po_line_uid[External ID],line_no[Line Number],supplier_part_no[Supplier Part ID],''[Requested Delivery Date],''[Requested By],''[Expense Type],'20020'[Account Code],item_id[Description],cast(unit_quantity as decimal(5))[Quantity],base_ut_price[Unit Price],''[Tax],pricing_unit[UOM],''[Is Receipt Required],''[VAT Amount],''[VAT Rate],''[Amount without VAT],''[Future],''[Custom]
from dbo.po_line pl
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
join po_hdr ph
on pl.po_no = ph.po_no
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid and ph.supplier_id = isu.supplier_id
where pl.po_no in(4012964)