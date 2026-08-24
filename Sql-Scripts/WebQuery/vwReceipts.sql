SELECT    Right(COALESCE (Inventory_supplier.manufacturing_class_id, Inventory_suppliertf.manufacturing_class_id, 'Blank'),2)[country_of_origin],CONVERT(DATETIME, CONVERT(CHAR(10), ISNULL(po_hdr_po_receipts.date_created, po_hdr_transfer_receipts.date_created), 120), 120) AS date_created_PO_hdr, CONVERT(DATETIME, CONVERT(CHAR(10), 
                         po_line.date_created, 120), 120) AS date_created_PO_line, CONVERT(DATETIME, CONVERT(CHAR(10), irl.date_created, 120), 120) AS date_created_receipt_line, CONVERT(DATETIME, CONVERT(CHAR(10), irh.date_created, 120), 
                         120) AS date_created_receipt_hdr, CONVERT(DATETIME, CONVERT(CHAR(10), ISNULL(po_hdr_po_receipts.date_last_modified, po_hdr_transfer_receipts.date_last_modified), 120), 120) AS date_last_modified_PO_hdr, 
                         CONVERT(DATETIME, CONVERT(CHAR(10), po_line.date_last_modified, 120), 120) AS date_last_modified_PO_line, CONVERT(DATETIME, CONVERT(CHAR(10), irl.date_last_modified, 120), 120) 
                         AS date_last_modified_receipt_line, CONVERT(DATETIME, CONVERT(CHAR(10), irh.date_last_modified, 120), 120) AS date_last_modified_receipt_hdr, irl.last_maintained_by AS created_by, 
                         ISNULL(po_hdr_po_receipts.created_by, po_hdr_transfer_receipts.created_by) AS created_by_PO_hdr, po_line.created_by AS created_by_PO_line, irl.created_by AS created_by_Received_line, 
                         irh.created_by AS created_by_Received_hdr, ISNULL(po_hdr_po_receipts.last_maintained_by, po_hdr_transfer_receipts.last_maintained_by) AS last_modified_by_PO_hdr, 
                         po_line.last_maintained_by AS last_modified_by_PO_line, irl.last_maintained_by AS last_modified_by_Received_line, irh.last_maintained_by AS last_modified_by_Received_hdr, Inventory_supplier.effective_date, 
                         Inventory_supplier.future_cost, COALESCE (Inventory_supplier.manufacturing_class_id, Inventory_suppliertf.manufacturing_class_id, 'Blank') AS manufacturing_class_id, mc.manufacturing_class_desc, supplier_ud.legacy_id, 
                         supplier_ud.legacy_company, po_hdr_po_receipts.external_po_no, irh.receipt_number, irh.po_number AS PONumber, irh.packing_slip_number, irh.freight_code_uid, irh.receiver_number, irh.receipt_type, irh.year_for_period, 
                         irh.period, CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) AS ReceivedDate, CONVERT(datetime, CONVERT(char(10), irh.shipment_date, 120), 120) AS Shipment_Date, irh.date_created, 1 AS line_count, 
                         irl.line_number AS LineNumber, irl.inv_mast_uid, COALESCE (po_schedule_receipts.qty_received, irl.qty_received) AS QtyReceived, irl.qty_vouched, irl.qty_lost, COALESCE (po_line_schedule.release_qty, po_line.qty_ordered) 
                         AS qty_ordered, irl.unit_of_measure AS UOM, irl.unit_cost_display, irl.unit_cost, irl.pricing_unit, irl.pricing_unit_size, irl.extended_cost_display, irl.freight_amount_vouched, irl.amount_vouched, irl.freight_amount, 
                         irl.extended_cost, irl.msp_landed_cost, irl.unit_size, irl.unit_quantity, irl.last_maintained_by, irl.vouch_complete, irl.po_line_number, 
                         CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.vendor_id WHEN 'P' THEN po_hdr_po_receipts.vendor_id END AS vendor_id, 
                         CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.vendor_id WHEN 'P' THEN po_hdr_po_receipts.vendor_id END AS vendor, 
                         CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.terms WHEN 'P' THEN po_hdr_po_receipts.terms END AS terms_id, 
                         CASE irh.receipt_type WHEN 'T' THEN inv_loctf.primary_supplier_id WHEN 'P' THEN po_hdr_po_receipts.supplier_id END AS supplier, 
                         CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.requested_by WHEN 'P' THEN po_hdr_po_receipts.requested_by END AS Buyer, 
                         CASE irh.receipt_type WHEN 'T' THEN ISNULL(po_hdr_transfer_receipts.carrier_id, '') WHEN 'P' THEN ISNULL(po_hdr_po_receipts.carrier_id, '') END AS Carrier, 
                         CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.po_type WHEN 'P' THEN po_hdr_po_receipts.po_type END AS POType, CASE irh.receipt_type WHEN 'T' THEN CONVERT(datetime, CONVERT(char(10), 
                         po_hdr_transfer_receipts.order_date, 120), 120) WHEN 'P' THEN CONVERT(datetime, CONVERT(char(10), po_hdr_po_receipts.order_date, 120), 120) END AS OrderDate, CASE irh.receipt_type WHEN 'T' THEN CONVERT(datetime, 
                         CONVERT(char(10), po_hdr_transfer_receipts.date_due, 120), 120) WHEN 'P' THEN CONVERT(datetime, CONVERT(char(10), po_hdr_po_receipts.date_due, 120), 120) END AS DueDate, 
                         CASE irh.receipt_type WHEN 'T' THEN ISNULL(po_hdr_transfer_receipts.sales_order_number, '0') WHEN 'P' THEN ISNULL(po_hdr_po_receipts.sales_order_number, '0') END AS SalesOrderNumber, 
                         CASE irh.receipt_type WHEN 'T' THEN transfer_hdr.to_location_id WHEN 'P' THEN po_hdr_po_receipts.location_id END AS location_id, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.po_class1 WHEN 'P' THEN po_hdr_po_receipts.po_class1 END, 'Blank') AS po_class1, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.po_class2 WHEN 'P' THEN po_hdr_po_receipts.po_class2 END, 'Blank') AS po_class2, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.po_class3 WHEN 'P' THEN po_hdr_po_receipts.po_class3 END, 'Blank') AS po_class3, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.po_class4 WHEN 'P' THEN po_hdr_po_receipts.po_class4 END, 'Blank') AS po_class4, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.po_class5 WHEN 'P' THEN po_hdr_po_receipts.po_class5 END, 'Blank') AS po_class5, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.branch_id WHEN 'P' THEN po_hdr_po_receipts.branch_id END, 'Blank') AS branch_id, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.division_id WHEN 'P' THEN po_hdr_po_receipts.division_id END, 0) AS division_id, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.source_type WHEN 'P' THEN po_hdr_po_receipts.source_type END, 0) AS source_type, po_line.unit_price_display, po_line.unit_price, 
                         COALESCE (CASE irh.receipt_type WHEN 'T' THEN vendorTF.vendor_name WHEN 'P' THEN vendor .vendor_name END, 'Blank') AS VendorName, 
                         CASE irh.receipt_type WHEN 'T' THEN transfer_hdr.company_id WHEN 'P' THEN po_hdr_po_receipts.company_no END AS Company_ID, 
                         CASE irh.receipt_type WHEN 'T' THEN transfer_hdr.company_id WHEN 'P' THEN po_hdr_po_receipts.company_no END AS Company_no, COALESCE (supplier.supplier_name, supplierTF.supplier_name, 'Blank') 
                         AS SupplierName, inv_mast.item_id, inv_mast.item_desc AS ItemDesc, COALESCE (inv_loc.stockable, inv_loctf.stockable) AS stockable, COALESCE (inv_loc.product_group_id, inv_loctf.product_group_id, 'Blank') 
                         AS product_group_id, COALESCE (inv_loc.primary_bin, inv_loctf.primary_bin, 'Blank') AS primary_bin, COALESCE (class.class_description, classtf.class_description, 'Blank') AS POClass1, COALESCE (CLass2.class_description, 
                         CLass2tf.class_description, 'Blank') AS POClass2, COALESCE (CLass3.class_description, CLass3tf.class_description, 'Blank') AS POClass3, COALESCE (CLass4.class_description, CLass4tf.class_description, 'Blank') 
                         AS POClass4, COALESCE (CLass5.class_description, CLass5tf.class_description, 'Blank') AS POClass5, 1.00 AS linecount, COALESCE (Inventory_supplier.supplier_part_no, Inventory_suppliertf.supplier_part_no, 'Blank') 
                         AS supplier_part_no, COALESCE (Buyers.buyer_name, Buyerstf.buyer_name, 'Blank') AS buyer_name, COALESCE (locationTF.location_name, location.location_name, 'Blank') AS location_name, 
                         COALESCE (branch.branch_description, branchtf.branch_description, 'Blank') AS branch_description, COALESCE (division.division_name, divisiontf.division_name, 'Blank') AS division_name, 
                         COALESCE (product_group.product_group_desc, product_grouptf.product_group_desc, 'Blank') AS product_group_desc, COALESCE (code.code_description, codetf.code_description, 'Blank') AS SourceDesc, 
                         COALESCE (Company.company_name, Company2.company_name) AS Company_Name, terms.terms_desc AS Terms, freight_code.freight_desc AS Freight, CAST(DATEDIFF(day, po_hdr_po_receipts.order_date, irh.date_created) 
                         AS decimal(19, 2)) AS DaystoReceive, COALESCE (po_line_schedule.release_date, po_line.required_date) AS required_date, CASE WHEN COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) 
                         = 'R' THEN 'Requisition PO' WHEN COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) 
                         = 'S' THEN 'Regular generated for stock requirements or manually generated' WHEN COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) 
                         = 'B' THEN 'Regular generated for backorders' WHEN COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) = 'D' THEN 'Direct Ship' WHEN COALESCE (po_hdr_po_receipts.po_type, 
                         po_hdr_transfer_receipts.PO_type) = 'P' THEN 'Special' WHEN COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) = 'N' THEN 'Non-Stock' WHEN COALESCE (po_hdr_po_receipts.po_type, 
                         po_hdr_transfer_receipts.PO_type) = 'X' THEN 'Secondary Process PO' WHEN COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) 
                         = 'Q' THEN 'Vendor RFQ' WHEN COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) = 'E' THEN 'Service Order PO' ELSE COALESCE (po_hdr_po_receipts.po_type, po_hdr_transfer_receipts.PO_type) 
                         END AS PO_Type, DATEADD(dd, supplier.days_early, COALESCE (po_line_schedule.release_date, po_line.required_date)) AS early_receipt_date, DATEADD(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, 
                         po_line.required_date)) AS late_receipt_date, CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_early, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) THEN 1.00 ELSE 0.00 END AS Count_early, CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) > CONVERT(datetime, 
                         CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) THEN 1.00 ELSE 0.00 END AS Count_late, CASE WHEN CONVERT(datetime, CONVERT(char(10), 
                         irh.date_created, 120), 120) >= CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_early, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) AND CONVERT(datetime, 
                         CONVERT(char(10), irh.date_created, 120), 120) <= CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) 
                         THEN 1.00 ELSE 0.00 END AS Countontime, CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) END AS DaysReceivedLate, CASE WHEN CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) 
                         < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), 
                         dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) END BETWEEN 1 AND 5 THEN 1.00 ELSE 0.00 END AS date1to5_late, 
                         CASE WHEN CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, 
                         po_line.required_date)), 120), 120) THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), 
                         irh.date_created) END BETWEEN 6 AND 10 THEN 1.00 ELSE 0.00 END AS date6to10_late, CASE WHEN CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), 
                         dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) END BETWEEN 11 AND 20 THEN 1.00 ELSE 0.00 END AS date11to20_late, CASE WHEN CASE WHEN CONVERT(datetime, 
                         CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) 
                         THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) 
                         END > 20 THEN 1.00 ELSE 0.00 END AS date0ver20, CASE WHEN CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) END BETWEEN 0 AND 2 THEN 1.00 ELSE 0.00 END AS date0to2_late, CASE WHEN CASE WHEN CONVERT(datetime, 
                         CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) 
                         THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) END BETWEEN 3 AND 
                         7 THEN 1.00 ELSE 0.00 END AS date3to7_late, CASE WHEN CASE WHEN CONVERT(datetime, CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, 
                         COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) END BETWEEN 8 AND 13 THEN 1.00 ELSE 0.00 END AS date8to13_late, CASE WHEN CASE WHEN CONVERT(datetime, 
                         CONVERT(char(10), irh.date_created, 120), 120) < CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120) 
                         THEN 0.00 ELSE DATEDIFF(dd, CONVERT(datetime, CONVERT(char(10), dateadd(dd, supplier.days_late, COALESCE (po_line_schedule.release_date, po_line.required_date)), 120), 120), irh.date_created) 
                         END > 13 THEN 1.00 ELSE 0.00 END AS dateOver13, CASE WHEN min_no = irl.receipt_number AND po_line.qty_ordered <= irl.qty_vouched THEN 'y' ELSE 'n' END AS First_receipt_filled_complete, iud.legacy_item_id, 
                         iud.legacy_item_description
FROM            dbo.inventory_receipts_hdr AS irh WITH (nolock) INNER JOIN
                         dbo.inventory_receipts_line AS irl WITH (nolock) ON irh.receipt_number = irl.receipt_number LEFT OUTER JOIN
                         dbo.inv_mast AS inv_mast WITH (nolock) ON irl.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         dbo.inv_mast_ud AS iud WITH (nolock) ON iud.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         dbo.transfer_shipment_hdr AS transfer_shipment_hdr WITH (NOLOCK) ON transfer_shipment_hdr.transfer_shipment_no = irh.po_number LEFT OUTER JOIN
                         dbo.transfer_hdr AS transfer_hdr WITH (NOLOCK) ON transfer_hdr.transfer_no = transfer_shipment_hdr.transfer_no LEFT OUTER JOIN
                         dbo.location AS transfer_receipt_location WITH (NOLOCK) ON transfer_receipt_location.location_id = transfer_hdr.to_location_id LEFT OUTER JOIN
                         dbo.po_hdr AS po_hdr_po_receipts WITH (NOLOCK) ON po_hdr_po_receipts.po_no = irh.po_number AND irh.receipt_type = 'P' LEFT OUTER JOIN
                         dbo.po_hdr AS po_hdr_transfer_receipts WITH (NOLOCK) ON po_hdr_transfer_receipts.po_no = transfer_hdr.transfer_no AND irh.receipt_type = 'T' LEFT OUTER JOIN
                         dbo.vendor AS vendorTF WITH (nolock) ON po_hdr_transfer_receipts.vendor_id = vendorTF.vendor_id AND po_hdr_transfer_receipts.company_no = vendorTF.company_id LEFT OUTER JOIN
                         dbo.vendor AS vendor WITH (nolock) ON po_hdr_po_receipts.vendor_id = vendor.vendor_id AND po_hdr_po_receipts.company_no = vendor.company_id LEFT OUTER JOIN
                         dbo.location AS location WITH (nolock) ON po_hdr_po_receipts.location_id = location.location_id LEFT OUTER JOIN
                         dbo.location AS locationTF WITH (noLock) ON transfer_hdr.to_location_id = locationTF.location_id LEFT OUTER JOIN
                         dbo.branch AS branch WITH (nolock) ON po_hdr_po_receipts.company_no = branch.company_id AND po_hdr_po_receipts.branch_id = branch.branch_id LEFT OUTER JOIN
                         dbo.branch AS branchtf WITH (nolock) ON po_hdr_transfer_receipts.company_no = branchtf.company_id AND po_hdr_transfer_receipts.branch_id = branchtf.branch_id LEFT OUTER JOIN
                         dbo.division AS division WITH (nolock) ON po_hdr_po_receipts.supplier_id = division.supplier_id AND po_hdr_po_receipts.division_id = division.division_id LEFT OUTER JOIN
                         dbo.division AS divisiontf WITH (nolock) ON po_hdr_transfer_receipts.supplier_id = divisiontf.supplier_id AND po_hdr_transfer_receipts.division_id = divisiontf.division_id LEFT OUTER JOIN
                         dbo.inv_loc AS inv_loc WITH (nolock) ON po_hdr_po_receipts.company_no = inv_loc.company_id AND po_hdr_po_receipts.location_id = inv_loc.location_id AND irl.inv_mast_uid = inv_loc.inv_mast_uid LEFT OUTER JOIN
                         dbo.inv_loc AS inv_loctf WITH (nolock) ON transfer_hdr.company_id = inv_loctf.company_id AND transfer_hdr.to_location_id = inv_loctf.location_id AND irl.inv_mast_uid = inv_loctf.inv_mast_uid LEFT OUTER JOIN
                         dbo.supplier AS supplier WITH (nolock) ON po_hdr_po_receipts.supplier_id = supplier.supplier_id LEFT OUTER JOIN
                         dbo.supplier AS supplierTF WITH (nolock) ON inv_loctf.primary_supplier_id = supplierTF.supplier_id LEFT OUTER JOIN
                         dbo.inventory_supplier AS Inventory_suppliertf WITH (nolock) ON inv_loctf.primary_supplier_id = Inventory_suppliertf.supplier_id AND inv_loctf.inv_mast_uid = Inventory_suppliertf.inv_mast_uid LEFT OUTER JOIN
                         dbo.inventory_supplier AS Inventory_supplier WITH (nolock) ON inv_loc.primary_supplier_id = Inventory_supplier.supplier_id AND inv_loc.inv_mast_uid = Inventory_supplier.inv_mast_uid LEFT OUTER JOIN
                         dbo.product_group AS product_group WITH (nolock) ON inv_loc.company_id = product_group.company_id AND inv_loc.product_group_id = product_group.product_group_id LEFT OUTER JOIN
                         dbo.product_group AS product_grouptf WITH (nolock) ON inv_loctf.company_id = product_grouptf.company_id AND inv_loctf.product_group_id = product_grouptf.product_group_id LEFT OUTER JOIN
                         dbo.po_line AS po_line WITH (nolock) ON irl.po_line_number = po_line.line_no AND irh.po_number = po_line.po_no LEFT OUTER JOIN
                         dbo.class AS class WITH (nolock) ON po_hdr_po_receipts.po_class1 = class.class_id AND class.class_number = 1 AND class.class_type = 'po' AND class.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass2 WITH (nolock) ON po_hdr_po_receipts.po_class2 = CLass2.class_id AND CLass2.class_number = 2 AND CLass2.class_type = 'po' AND CLass2.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass3 WITH (nolock) ON po_hdr_po_receipts.po_class3 = CLass3.class_id AND CLass3.class_number = 3 AND CLass3.class_type = 'po' AND CLass3.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass4 WITH (nolock) ON po_hdr_po_receipts.po_class4 = CLass4.class_id AND CLass4.class_number = 4 AND CLass4.class_type = 'po' AND CLass4.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass5 WITH (nolock) ON po_hdr_po_receipts.po_class5 = CLass5.class_id AND CLass5.class_number = 5 AND CLass5.class_type = 'po' AND CLass5.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS classtf ON po_hdr_transfer_receipts.po_class1 = classtf.class_id AND classtf.class_number = 1 AND classtf.class_type = 'po' AND classtf.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass2tf WITH (nolock) ON po_hdr_transfer_receipts.po_class2 = CLass2tf.class_id AND CLass2tf.class_number = 2 AND CLass2tf.class_type = 'po' AND CLass2tf.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass3tf WITH (nolock) ON po_hdr_transfer_receipts.po_class3 = CLass3tf.class_id AND CLass3tf.class_number = 3 AND CLass3tf.class_type = 'po' AND CLass3tf.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass4tf WITH (nolock) ON po_hdr_transfer_receipts.po_class4 = CLass4tf.class_id AND CLass4tf.class_number = 4 AND CLass4tf.class_type = 'po' AND CLass4tf.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS CLass5tf WITH (nolock) ON po_hdr_transfer_receipts.po_class5 = CLass5tf.class_id AND CLass5tf.class_number = 5 AND CLass5tf.class_type = 'po' AND CLass5tf.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.company AS Company WITH (nolock) ON po_hdr_po_receipts.company_no = Company.company_id LEFT OUTER JOIN
                         dbo.company AS Company2 WITH (nolock) ON transfer_hdr.company_id = Company2.company_id LEFT OUTER JOIN
                         dbo.code_p21 AS code WITH (nolock) ON code.code_no = po_hdr_po_receipts.source_type LEFT OUTER JOIN
                         dbo.code_p21 AS codetf WITH (nolock) ON codetf.code_no = po_hdr_transfer_receipts.source_type LEFT OUTER JOIN
                         dbo.po_schedule_receipts AS po_schedule_receipts ON irl.receipt_number = po_schedule_receipts.receipt_number AND irl.line_number = po_schedule_receipts.line_number LEFT OUTER JOIN
                         dbo.po_line_schedule AS po_line_schedule ON po_line_schedule.po_line_schedule_uid = po_schedule_receipts.po_line_schedule_uid LEFT OUTER JOIN
                         dbo.freight_code AS freight_code WITH (nolock) ON irh.freight_code_uid = freight_code.freight_code_uid AND 
                         freight_code.company_id = CASE irh.receipt_type WHEN 'T' THEN transfer_hdr.company_id WHEN 'P' THEN po_hdr_po_receipts.company_no END LEFT OUTER JOIN
                             (SELECT        irh.po_number, irl.po_line_number, MIN(irl.receipt_number) AS min_no
                               FROM            dbo.inventory_receipts_hdr AS irh WITH (nolock) INNER JOIN
                                                         dbo.inventory_receipts_line AS irl WITH (nolock) ON irh.receipt_number = irl.receipt_number
                               GROUP BY irh.po_number, irl.po_line_number) AS m ON m.po_number = irh.po_number AND m.po_line_number = irl.po_line_number LEFT OUTER JOIN
                         dbo.terms AS terms WITH (nolock) ON terms.terms_id = CASE irh.receipt_type WHEN 'T' THEN po_hdr_transfer_receipts.terms WHEN 'P' THEN po_hdr_po_receipts.terms END LEFT OUTER JOIN
                             (SELECT        id, last_name + ', ' + first_name AS buyer_name
                               FROM            dbo.contacts AS Contactstf WITH (nolock)
                               WHERE        (delete_flag = 'N') AND (buyer = 'Y')) AS Buyerstf ON po_hdr_transfer_receipts.requested_by = Buyerstf.id LEFT OUTER JOIN
                             (SELECT        id, last_name + ', ' + first_name AS buyer_name
                               FROM            dbo.contacts AS Contactstf WITH (nolock)
                               WHERE        (delete_flag = 'N') AND (buyer = 'Y')) AS Buyers ON po_hdr_po_receipts.requested_by = Buyers.id LEFT OUTER JOIN
                         dbo.manufacturing_class AS mc WITH (nolock) ON mc.manufacturing_class_id = COALESCE (Inventory_supplier.manufacturing_class_id, Inventory_suppliertf.manufacturing_class_id, 'Blank') LEFT OUTER JOIN
                         dbo.supplier_ud AS supplier_ud WITH (nolock) ON supplier_ud.supplier_id = CASE irh.receipt_type WHEN 'T' THEN inv_loctf.primary_supplier_id WHEN 'P' THEN po_hdr_po_receipts.supplier_id END
WHERE        (irh.delete_flag = 'N') AND (irh.approved = 'Y') 