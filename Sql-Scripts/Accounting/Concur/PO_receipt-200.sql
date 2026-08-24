-- pl.po_line_uid

select '200'[Record type],po_number[Purchase Order Number],m.item_id[Line Item External ID],irh.receipt_number[Goods Receipt Number],irl.inventory_receipts_line_uid[Delivery Slip Number],irl.unit_of_measure[UOM Code],irl.qty_received[Received Quantity],convert(varchar(10),irl.date_created,120)[Received Date],''[Is Deleted],''[Future],''[Custom]
from dbo.inventory_receipts_hdr irh
join dbo.inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join dbo.inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
where po_number = 4013508
/*where po_number in (4013889,4013545,4013872,4013104,4013423,4012437,4013417,4012410,4013416,4013510,4013016,4013137,4011341,4013508,4013566,4013351,4012998,4013248,4013389,4013004,4013053,4013566,4012729,4013015,4013508,4013014,4013105,4013045,4011435,4012766,4013053,4011341,4013280)*/
order by pl.po_line_uid


select *
from inventory_receipts_line
where receipt_number = 5036532

select *
from inventory_receipts_hdr
where po_number = 4013104

select '200'[Record type],po_number[Purchase Order Number],m.item_id[Line Item External ID],irh.receipt_number[Goods Receipt Number],irl.inventory_receipts_line_uid[Delivery Slip Number],irl.unit_of_measure[UOM Code],irl.qty_received[Received Quantity],convert(varchar(10),irl.date_created,120)[Received Date],''[Is Deleted],''[Future],''[Custom]
from inventory_receipts_hdr irh
join inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
where po_number = 4013104

select '200'[Record type],po_number[Purchase Order Number],m.item_id[Line Item External ID],irh.receipt_number[Goods Receipt Number],irl.inventory_receipts_line_uid[Delivery Slip Number],irl.unit_of_measure[UOM Code],irl.qty_received[Received Quantity],convert(varchar(10),irl.date_created,120)[Received Date],''[Is Deleted],''[Future],''[Custom]
from inventory_receipts_hdr irh
join inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
where po_number = 4013889

-- latest 
select '200'[Record type],po_number[Purchase Order Number],pl.po_line_uid[Line Item External ID],m.item_id,irh.receipt_number[Goods Receipt Number],irl.inventory_receipts_line_uid[Delivery Slip Number],irl.unit_of_measure[UOM Code],cast(irl.qty_received as decimal(5))[Received Quantity],convert(varchar(10),irl.date_created,120)[Received Date],''[Is Deleted],''[Future],''[Custom]
from dbo.inventory_receipts_hdr irh
join dbo.inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join dbo.inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
join dbo.po_line pl
on pl.inv_mast_uid = m.inv_mast_uid and pl.line_no = irl.po_line_number and irh.po_number = pl.po_no
where po_number = 4013508
/*where po_number in (4013889,4013545,4013872,4013104,4013423,4012437,4013417,4012410,4013416,4013510,4013016,4013137,4011341,4013508,4013566,4013351,4012998,4013248,4013389,4013004,4013053,4013566,4012729,4013015,4013508,4013014,4013105,4013045,4011435,4012766,4013053,4011341,4013280)*/
order by pl.po_line_uid


select *
from po_line
where po_no = 4013508


-- Daily queries

select '200'[Record type],po_number[Purchase Order Number],pl.po_line_uid[Line Item External ID],m.item_id,irh.receipt_number[Goods Receipt Number],irl.inventory_receipts_line_uid[Delivery Slip Number],irl.unit_of_measure[UOM Code],cast(irl.qty_received as decimal(5))[Received Quantity],convert(varchar(10),irl.date_created,120)[Received Date],''[Is Deleted],''[Future],''[Custom]
from dbo.inventory_receipts_hdr irh
join dbo.inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join dbo.inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
join dbo.po_line pl
on pl.inv_mast_uid = m.inv_mast_uid and pl.line_no = irl.po_line_number and irh.po_number = pl.po_no
where irl.date_created between DATEADD(day, -1, GETDATE()) and DATEADD(day, 1, GETDATE()) 
order by [Purchase Order Number]

select distinct po_number
from dbo.inventory_receipts_hdr irh
join dbo.inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join dbo.po_line pl
on  pl.line_no = irl.po_line_number and irh.po_number = pl.po_no
where irl.date_created between DATEADD(day, -1, GETDATE()) and DATEADD(day, 1, GETDATE()) 
order by po_number

select *
from inventory_receipts_hdr
where po_number = 5601

select '200'[Record type],po_number[Purchase Order Number],pl.po_line_uid[Line Item External ID],m.item_id,irh.receipt_number[Goods Receipt Number],irl.inventory_receipts_line_uid[Delivery Slip Number],irl.unit_of_measure[UOM Code],cast(irl.qty_received as decimal(5))[Received Quantity],convert(varchar(10),irl.date_created,120)[Received Date],''[Is Deleted],''[Future],''[Custom]
from dbo.inventory_receipts_hdr irh
join dbo.inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join dbo.inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
join dbo.po_line pl
on pl.inv_mast_uid = m.inv_mast_uid and pl.line_no = irl.po_line_number and irh.po_number = pl.po_no
where po_number = 4016318
