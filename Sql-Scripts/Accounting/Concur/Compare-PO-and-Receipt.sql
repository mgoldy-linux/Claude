select '200'[Record type],po_number[Purchase Order Number],m.item_id[Line Item External ID],irh.receipt_number[Goods Receipt Number],irl.inventory_receipts_line_uid[Delivery Slip Number],irl.unit_of_measure[UOM Code],irl.qty_received[Received Quantity],convert(varchar(10),irl.date_created,120)[Received Date],''[Is Deleted],''[Future],''[Custom]
from inventory_receipts_hdr irh
join inventory_receipts_line irl 
on irh.receipt_number = irl.receipt_number
join inv_mast m
on m.inv_mast_uid = irl.inv_mast_uid
where po_number = 4013053

Select '300'[Record Type],item_id[External ID],line_no[Line Number],supplier_part_no[Supplier Part ID],''[Requested Delivery Date],''[Requested By],'Expense Type'[Expense Type],'Account Code'[Account Code],pl.item_description[Description],unit_quantity[Quantity],base_ut_price[Unit Price],''[Tax],pricing_unit[UOM],''[Is Receipt Required],''[VAT Amount],''[VAT Rate],''[Amount without VAT],''[Future],''[Custom]
from dbo.po_line pl
join dbo.inv_mast m
on pl.inv_mast_uid = m.inv_mast_uid
join po_hdr ph
on pl.po_no = ph.po_no
join dbo.inventory_supplier isu
on m.inv_mast_uid = isu.inv_mast_uid and ph.supplier_id = isu.supplier_id
where pl.po_no = 4013053