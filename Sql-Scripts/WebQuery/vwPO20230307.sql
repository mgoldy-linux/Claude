SELECT  CASE WHEN po_line.date_due_last_modified IS NOT NULL THEN 'Y' ELSE 'N' END date_due_edited,po_line.expected_ship_date,      po_hdr.exchange_rate, h.currency_desc, CAST(YEAR(po_hdr.order_date) AS varchar(4)) + CASE WHEN month(po_hdr.order_date) < 10 THEN '0' + CAST(month(po_hdr.order_date) AS varchar(2)) 
                         ELSE CAST(month(po_hdr.order_date) AS varchar(2)) END AS Order_Year_month, CAST(YEAR(po_line.received_date) AS varchar(4)) + CASE WHEN month(po_line.received_date) 
                         < 10 THEN '0' + CAST(month(po_line.received_date) AS varchar(2)) ELSE CAST(month(po_line.received_date) AS varchar(2)) END AS Received_Year_month, 
                         inv_loc.qty_on_hand + inv_loc.order_quantity - ISNULL(vw365d.qty_shipped_365d, 0) AS surplus_qty, inv_loc.qty_on_hand, inv_loc.order_quantity, po_line.delete_flag AS line_delete, po_hdr.delete_flag AS hdr_delete, 
                         CONVERT(DATETIME, CONVERT(CHAR(10), po_hdr.date_created, 120), 120) AS date_created_hdr, CONVERT(DATETIME, CONVERT(CHAR(10), po_line.date_created, 120), 120) AS date_created_line, CONVERT(DATETIME, 
                         CONVERT(CHAR(10), po_hdr.date_last_modified, 120), 120) AS date_last_modified_hdr, CONVERT(DATETIME, CONVERT(CHAR(10), po_line.date_last_modified, 120), 120) AS date_last_modified_line, 
                         po_hdr.created_by AS created_by_hdr, po_line.created_by AS created_by_line, po_hdr.last_maintained_by AS last_modified_by_hdr, po_line.last_maintained_by AS last_modified_by_line, supplier_ud.legacy_id, 
                         po_hdr.external_po_no, supplier_ud.legacy_company, Inventory_supplier.manufacturing_class_id, mc.manufacturing_class_desc, po_hdr.packing_basis, 
                         CASE WHEN transmission_method = 708 THEN 'EDI' ELSE 'Paper' END AS Transmission_method, po_hdr.company_no, po_hdr.vendor_id, po_hdr.po_no AS PONumber, po_hdr.company_no AS Company, 
                         po_hdr.vendor_id AS Vendor, po_hdr.supplier_id AS Supplier, po_hdr.requested_by AS Buyer, ISNULL(po_hdr.cancel_flag, '') AS HdrCancelled, CONVERT(DATETIME, CONVERT(CHAR(10), po_hdr.order_date, 120), 120) 
                         AS OrderDate, po_hdr.complete AS HdrComplete, po_line.unit_of_measure AS UOM, po_line.unit_price AS UnitPrice, po_line.unit_price_display AS Unit_Price_PO_currency, po_line.pricing_unit_size AS UnitSize, 
                         ROUND((po_line.unit_quantity * po_line.unit_size) * (po_line.unit_price / po_line.pricing_unit_size), 2) AS OrderDollars, ROUND((po_line.unit_quantity * po_line.unit_size) * (po_line.unit_price_display / po_line.pricing_unit_size),
                          2) AS OrderDollars_PO_currency, ROUND(po_line.unit_price * ((po_line.qty_ordered - po_line.qty_received) / po_line.pricing_unit_size), 2) AS OpenDollars, 
                         ROUND(po_line.unit_price_display * ((po_line.qty_ordered - po_line.qty_received) / po_line.pricing_unit_size), 2) AS OpenDollars_PO_currency, ROUND(po_line.unit_price * (po_line.qty_received / po_line.pricing_unit_size), 2) 
                         AS ReceivedDollars, ROUND(po_line.unit_price_display * (po_line.qty_received / po_line.pricing_unit_size), 2) AS ReceivedDollars_PO_currency, 
                         CASE WHEN po_type = 'R' THEN 'Requisition PO' WHEN po_type = 'S' THEN 'Regular generated for stock requirements or manually generated' WHEN po_type = 'B' THEN 'Regular generated for backorders' WHEN po_type = 'D'
                          THEN 'Direct Ship' WHEN po_type = 'P' THEN 'Special' WHEN po_type = 'N' THEN 'Non-Stock' WHEN po_type = 'X' THEN 'Secondary Process PO' WHEN po_type = 'Q' THEN 'Vendor RFQ' WHEN po_type = 'E' THEN 'Service Order PO'
                          ELSE po_type END AS POType, po_hdr.terms, ISNULL(po_hdr.sales_order_number, '0') AS SalesOrderNumber, po_hdr.po_class1, po_hdr.po_class3, po_hdr.division_id, po_hdr.po_class2, po_hdr.po_class4, 
                         po_hdr.po_class5, COALESCE (po_hdr.branch_id, location.default_branch_id) AS branch_id, po_hdr.location_id, po_line.line_no AS LineNumber, ISNULL(po_line.line_type, '') AS LineType, po_line.cancel_flag AS LineCancelled, 
                         CONVERT(DATETIME, CONVERT(CHAR(10), po_line.date_due, 120), 120) AS DueDate, CONVERT(DATETIME, CONVERT(CHAR(10), po_line.received_date, 120), 120) AS ReceivedDate, CONVERT(DATETIME, CONVERT(CHAR(10), 
                         po_line.required_date, 120), 120) AS RequiredDate, po_line.complete AS LineComplete, po_line.inv_mast_uid, po_line.qty_ordered AS QtyOrdered, po_line.qty_received AS QtyReceived, po_line.item_description AS ItemDesc, 
                         inv_mast.item_id, inv_loc.standard_cost, inv_loc.price1, inv_loc.product_group_id, inv_loc.sales_discount_group, inv_loc.purchase_discount_group, COALESCE (inv_loc.primary_bin, 'Blank') AS primary_bin, 
                         ISNULL(class.class_description, 'Blank') AS POClass1, ISNULL(CLass2.class_description, 'Blank') AS POClass2, ISNULL(CLass3.class_description, 'Blank') AS POClass3, ISNULL(CLass4.class_description, 'Blank') 
                         AS POClass4, ISNULL(CLass5.class_description, 'Blank') AS POClass5, CASE WHEN po_line.required_date >= GetDate() THEN 0 ELSE Datediff(day, po_line.required_date, getdate()) END AS DaysLate, 
                         CASE WHEN po_line.date_due >= GetDate() THEN 0 ELSE Datediff(day, po_line.date_due, getdate()) END AS DaysLate_due_date, CASE WHEN po_line.received_date IS NULL 
                         THEN 0 WHEN po_line.received_date <= po_line.required_date THEN 0 ELSE DateDiff(day, po_line.required_date, po_line.received_date) END AS DaysReceivedLate, CASE WHEN po_line.received_date IS NULL 
                         THEN 0 WHEN po_line.required_date <= po_line.received_date THEN 0 ELSE DateDiff(day, po_line.received_date, po_line.required_date) END AS DaysReceivedEarly, CAST(CASE WHEN datediff(dd, CONVERT(DATETIME, 
                         CONVERT(CHAR(10), po_line.required_date, 120), 120), CONVERT(DATETIME, CONVERT(CHAR(10), po_line.received_date, 120), 120)) > 0 THEN 0 ELSE 1 END AS DECIMAL(19, 9)) AS CountOnTime, 1 AS linecount, 
                         vendor.vendor_name AS VendorName, supplier.supplier_name AS SupplierName, Buyers.buyer_name, location.location_name, branch.branch_description, division.division_name, product_group.product_group_desc, 
                         Company.company_name, COALESCE (Carrier_Address.name, 'Blank') AS Carrier, discount_group_s.discount_group_description AS SalesGroup, discount_group_p.discount_group_description AS PurchGroup, 
                         po_line.qty_ordered - po_line.qty_received AS qty_open, vessel.qty_on_vessel, Inventory_supplier.supplier_sort_code, iud.legacy_item_id, iud.legacy_item_description, Inventory_supplier.effective_date, 
                         Inventory_supplier.future_cost, Inventory_supplier.upc_code, container.container, container.qty_on_container AS total_qty_on_container, po_line.required_date
FROM            Play2.dbo.po_hdr AS po_hdr WITH (NOLOCK) LEFT OUTER JOIN
                         Play2.dbo.company AS Company WITH (NOLOCK) ON po_hdr.company_no = Company.company_id INNER JOIN
                         Play2.dbo.po_line AS po_line WITH (NOLOCK) ON po_hdr.po_no = po_line.po_no INNER JOIN
                         Play2.dbo.vendor AS vendor WITH (NOLOCK) ON po_hdr.vendor_id = vendor.vendor_id AND po_hdr.company_no = vendor.company_id INNER JOIN
                         Play2.dbo.supplier AS supplier WITH (NOLOCK) ON po_hdr.supplier_id = supplier.supplier_id INNER JOIN
                         Play2.dbo.inv_mast AS inv_mast WITH (NOLOCK) ON po_line.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         Play2.dbo.inv_mast_ud AS iud WITH (NOLOCK) ON iud.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                             (SELECT        id, last_name + ', ' + first_name AS buyer_name
                               FROM            Play2.dbo.contacts AS Contacts WITH (NOLOCK)
                               WHERE        (delete_flag = 'N') AND (buyer = 'Y')) AS Buyers ON po_hdr.requested_by = Buyers.id LEFT OUTER JOIN
                         Play2.dbo.class AS class ON po_hdr.po_class1 = class.class_id AND class.class_number = 1 AND class.class_type = 'po' AND class.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass2 WITH (NOLOCK) ON po_hdr.po_class2 = CLass2.class_id AND CLass2.class_number = 2 AND CLass2.class_type = 'po' AND CLass2.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass3 WITH (NOLOCK) ON po_hdr.po_class3 = CLass3.class_id AND CLass3.class_number = 3 AND CLass3.class_type = 'po' AND CLass3.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass4 WITH (NOLOCK) ON po_hdr.po_class4 = CLass4.class_id AND CLass4.class_number = 4 AND CLass4.class_type = 'po' AND CLass4.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass5 WITH (NOLOCK) ON po_hdr.po_class5 = CLass5.class_id AND CLass5.class_number = 5 AND CLass5.class_type = 'po' AND CLass5.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.location AS location WITH (NOLOCK) ON po_hdr.company_no = location.company_id AND po_hdr.location_id = location.location_id LEFT OUTER JOIN
                         Play2.dbo.branch AS branch WITH (NOLOCK) ON po_hdr.company_no = branch.company_id AND po_hdr.branch_id = branch.branch_id LEFT OUTER JOIN
                         Play2.dbo.division AS division WITH (NOLOCK) ON po_hdr.supplier_id = division.supplier_id AND po_hdr.division_id = division.division_id LEFT OUTER JOIN
                         Play2.dbo.inv_loc AS inv_loc WITH (NOLOCK) ON po_hdr.company_no = inv_loc.company_id AND po_hdr.location_id = inv_loc.location_id AND po_line.inv_mast_uid = inv_loc.inv_mast_uid LEFT OUTER JOIN
                         Play2.dbo.product_group AS product_group WITH (NOLOCK) ON inv_loc.company_id = product_group.company_id AND inv_loc.product_group_id = product_group.product_group_id LEFT OUTER JOIN
                         Play2.dbo.address AS Carrier_Address ON Carrier_Address.carrier_flag = 'y' AND Carrier_Address.delete_flag = 'n' AND po_hdr.carrier_id = Carrier_Address.id LEFT OUTER JOIN
                         Play2.dbo.discount_group AS discount_group_p WITH (NOLOCK) ON discount_group_p.delete_flag = 'N' AND discount_group_p.discount_group_id = inv_loc.purchase_discount_group LEFT OUTER JOIN
                         Play2.dbo.discount_group AS discount_group_s WITH (NOLOCK) ON discount_group_s.delete_flag = 'N' AND discount_group_s.discount_group_id = inv_loc.sales_discount_group LEFT OUTER JOIN
                             (SELECT        po_line.po_no, po_line.line_no, SUM(CAST(vessel_receipts_line.container_qty_received AS INT) - vessel_receipts_line.container_qty_unloaded) AS qty_on_vessel
                               FROM            Play2.dbo.vessel_receipts_line AS vessel_receipts_line LEFT OUTER JOIN
                                                         Play2.dbo.po_line AS po_line WITH (NOLOCK) ON vessel_receipts_line.po_line_uid = po_line.po_line_uid AND po_line.complete <> 'y'
                               WHERE        (vessel_receipts_line.row_status_flag NOT IN (701, 976))
                               GROUP BY po_line.po_no, po_line.line_no) AS vessel ON vessel.po_no = po_line.po_no AND vessel.line_no = po_line.line_no LEFT OUTER JOIN
                         Play2.dbo.inventory_supplier AS Inventory_supplier WITH (NOLOCK) ON po_hdr.supplier_id = Inventory_supplier.supplier_id AND po_line.inv_mast_uid = Inventory_supplier.inv_mast_uid LEFT OUTER JOIN
                         Play2.dbo.manufacturing_class AS mc WITH (NOLOCK) ON mc.manufacturing_class_id = Inventory_supplier.manufacturing_class_id LEFT OUTER JOIN
                         Play2.dbo.supplier_ud AS supplier_ud WITH (NOLOCK) ON supplier_ud.supplier_id = inv_loc.primary_supplier_id LEFT OUTER JOIN
                             (SELECT        bp.po_line_uid, string_agg(b.container_name, ';') AS container, SUM(bp.po_container_unit_qty) AS qty_on_container
                               FROM            Play2.dbo.container_building_po AS bp WITH (nolocK) LEFT OUTER JOIN
                                                         Play2.dbo.container_building AS b WITH (nolock) ON b.container_building_uid = bp.container_building_uid LEFT OUTER JOIN
                                                         Play2.dbo.po_line AS p WITH (nolock) ON p.po_line_uid = bp.po_line_uid LEFT OUTER JOIN
                                                         Play2.dbo.vessel_receipts_container AS vs WITH (nolock) ON vs.container_building_uid = b.container_building_uid
                               WHERE        (bp.row_status_flag = 702) AND (bp.po_container_unit_qty > 0) AND (p.complete = 'n') AND (ISNULL(p.cancel_flag, 'n') = 'n') AND (ISNULL(p.delete_flag, 'n') = 'n') AND (vs.received_date IS NULL) AND 
                                                         (vs.vessel_receipts_container_uid IS NOT NULL)
                               GROUP BY bp.po_line_uid) AS container ON container.po_line_uid = po_line.po_line_uid LEFT OUTER JOIN
                         dbo.R12_sales AS vw365d ON inv_loc.company_id = vw365d.company_no AND inv_loc.inv_mast_uid = vw365d.inv_mast_uid AND inv_loc.location_id = vw365d.sales_location_id LEFT OUTER JOIN
                         Play2.dbo.currency_hdr AS h WITH (nolock) ON h.currency_id = po_hdr.currency_id
WHERE        (po_line.cancel_flag = 'N') AND (po_hdr.po_type <> 'Q') OR
                         (po_hdr.po_type <> 'Q') AND (po_line.qty_received > 0)