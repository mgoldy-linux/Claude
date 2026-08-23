SELECT        po_hdr.external_po_no, lc_driver_x_tran.multiplier, inventory_receipts_hdr.transaction_number AS receipt_number, rh.receipt_number AS inv_receipt_number, CONVERT(DATETIME, CONVERT(CHAR(10), 
                         inventory_receipts_hdr.receipt_date, 120), 120) AS receipt_date, inventory_receipts_hdr.transaction_number, 
                         CASE inventory_receipts_hdr.receipt_type WHEN 'P' THEN 'Purchase Order' WHEN 'T' THEN 'Transfer' WHEN 'V' THEN 'Vessel' WHEN 'C' THEN 'Container' END AS transaction_type, landed_cost_driver.company_id, 
                         company.company_name, inventory_receipts_hdr.location_id AS receipt_location_id, 'Location #' + RTRIM(CAST(inventory_receipts_hdr.location_id AS CHAR(20))) + ', ' + location.location_name AS location_info, 
                         inventory_receipts_hdr.receipt_type, inventory_receipts_hdr.external_reference_no, landed_cost_driver.currency_id, currency_hdr.currency_desc, landed_cost_driver.landed_cost_driver_cd, 
                         landed_cost_driver.landed_cost_driver_desc, lc_driver_x_tran.landed_cost_amt AS landed_cost_amt_total, lc_driver_x_tran_detail.landed_cost_amt, lc_driver_x_tran_detail.amount_paid, 
                         COALESCE (landed_cost_driver_tax.tax_driver_flag, 'N') AS tax_driver_flag, landed_cost_driver_tax.tax_id_no, landed_cost_driver_tax.tax_expiration_date, landed_cost_driver.landed_cost_driver_uid, 
                         CASE WHEN landed_cost_driver.currency_id <> company.home_currency_id THEN 'F' ELSE 'H' END AS currency_type, po_line.po_no AS po_number, po_hdr.vendor_id, vendor.vendor_name AS VendorName, 
                         CASE WHEN po_hdr.po_type = 'R' THEN 'Requisition PO' WHEN po_hdr.po_type = 'S' THEN 'Regular generated for stock requirements or manually generated' WHEN po_hdr.po_type = 'B' THEN 'Regular generated for backorders'
                          WHEN po_hdr.po_type = 'D' THEN 'Direct Ship' WHEN po_hdr.po_type = 'P' THEN 'Special' WHEN po_hdr.po_type = 'N' THEN 'Non-Stock' WHEN po_hdr.po_type = 'X' THEN 'Secondary Process PO' WHEN po_hdr.po_type = 'Q'
                          THEN 'Vendor RFQ' WHEN po_hdr.po_type = 'E' THEN 'Service Order PO' ELSE po_hdr.po_type END AS PO_Type, CASE WHEN isnull(currency_line.exchange_rate, 0) <= 0 THEN (lc_driver_x_tran_detail.landed_cost_amt) 
                         WHEN (lc_driver_x_tran_detail.landed_cost_amt) IS NULL THEN 0 ELSE (lc_driver_x_tran_detail.landed_cost_amt) / currency_line.exchange_rate END AS landed_cost_amt_home, 
                         inventory_receipts_hdr.external_reference_no AS container_name,
                             (SELECT        code_description
                               FROM            P21.dbo.code_p21
                               WHERE        (code_no = con.row_status_flag)) AS Container_status, p.code_description AS calculation_method, inventory_receipts_hdr.lc_driver_x_tran_uid, con.vessel_receipts_hdr_uid AS Vessel_receipt_number, 
                         vessel_receipts_hdr.vessel_name, po_line.po_no, po_line.line_no AS PO_Line_no, m.item_id, m.item_desc, 
                         vessel_receipts_line.container_qty_received / CASE WHEN vessel_receipts_line.container_unit_size = 0 THEN 1 ELSE vessel_receipts_line.container_unit_size END AS container_qty_received, 
                         vessel_receipts_line.container_qty_unloaded / CASE WHEN vessel_receipts_line.container_unit_size = 0 THEN 1 ELSE vessel_receipts_line.container_unit_size END AS container_qty_unloaded, 
                         vessel_receipts_line.container_uom AS UOM, rh.period AS receipt_period, rh.year_for_period AS receipt_year, m.inv_mast_uid, rh.container_receipts_hdr_uid, iud.legacy_item_id, iud.legacy_item_description, 
                         Inventory_supplier.future_cost, Inventory_supplier.effective_date, po_line.unit_price, po_hdr.supplier_id, supplier.supplier_name
FROM            P21.dbo.p21_view_lc_invhdr_receipts AS inventory_receipts_hdr WITH (NOLOCK) INNER JOIN
                         P21.dbo.lc_driver_x_tran AS lc_driver_x_tran WITH (NOLOCK) ON lc_driver_x_tran.lc_driver_x_tran_uid = inventory_receipts_hdr.lc_driver_x_tran_uid LEFT OUTER JOIN
                         P21.dbo.lc_driver_x_tran_detail AS lc_driver_x_tran_detail WITH (nolock) ON lc_driver_x_tran_detail.transaction_number = lc_driver_x_tran.transaction_number AND 
                         lc_driver_x_tran.landed_cost_driver_uid = lc_driver_x_tran_detail.landed_cost_driver_uid LEFT OUTER JOIN
                         P21.dbo.vessel_receipts_container AS con WITH (Nolock) ON con.container_name = inventory_receipts_hdr.external_reference_no LEFT OUTER JOIN
                         P21.dbo.vessel_receipts_hdr AS vessel_receipts_hdr WITH (nolock) ON vessel_receipts_hdr.vessel_receipts_hdr_uid = con.vessel_receipts_hdr_uid LEFT OUTER JOIN
                         P21.dbo.vessel_receipts_line AS vessel_receipts_line WITH (nolock) ON vessel_receipts_line.vessel_receipts_hdr_uid = vessel_receipts_hdr.vessel_receipts_hdr_uid AND 
                         vessel_receipts_line.line_no = lc_driver_x_tran_detail.line_no LEFT OUTER JOIN
                         P21.dbo.po_line AS po_line WITH (nolock) ON po_line.po_line_uid = vessel_receipts_line.po_line_uid LEFT OUTER JOIN
                         P21.dbo.po_hdr AS po_hdr WITH (NOLOCK) ON po_hdr.po_no = po_line.po_no LEFT OUTER JOIN
                         P21.dbo.supplier AS supplier WITH (NOLOCK) ON supplier.supplier_id = po_hdr.supplier_id LEFT OUTER JOIN
                             (SELECT        irh.period, irh.year_for_period, irh.container_receipts_hdr_uid, po_line.po_line_uid, irh.receipt_number
                               FROM            P21.dbo.inventory_receipts_hdr AS irh WITH (nolock) INNER JOIN
                                                         P21.dbo.inventory_receipts_line AS irl WITH (nolock) ON irh.receipt_number = irl.receipt_number LEFT OUTER JOIN
                                                         P21.dbo.po_line AS po_line WITH (nolock) ON irl.po_line_number = po_line.line_no AND irh.po_number = po_line.po_no) AS rh ON rh.container_receipts_hdr_uid = inventory_receipts_hdr.transaction_number AND 
                         rh.po_line_uid = vessel_receipts_line.po_line_uid INNER JOIN
                         P21.dbo.landed_cost_driver AS landed_cost_driver WITH (NOLOCK) ON lc_driver_x_tran_detail.landed_cost_driver_uid = landed_cost_driver.landed_cost_driver_uid LEFT OUTER JOIN
                         P21.dbo.inv_mast AS m WITH (nolock) ON m.inv_mast_uid = po_line.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.inv_mast_ud AS iud WITH (nolock) ON iud.inv_mast_uid = m.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.vendor AS vendor WITH (NOLOCK) ON po_hdr.vendor_id = vendor.vendor_id AND po_hdr.company_no = vendor.company_id INNER JOIN
                         P21.dbo.company AS company WITH (NOLOCK) ON landed_cost_driver.company_id = company.company_id INNER JOIN
                         P21.dbo.currency_hdr AS currency_hdr WITH (NOLOCK) ON currency_hdr.currency_id = landed_cost_driver.currency_id LEFT OUTER JOIN
                         P21.dbo.location AS location WITH (NOLOCK) ON location.location_id = inventory_receipts_hdr.location_id LEFT OUTER JOIN
                         P21.dbo.landed_cost_driver_tax AS landed_cost_driver_tax WITH (NOLOCK) ON landed_cost_driver.landed_cost_driver_uid = landed_cost_driver_tax.landed_cost_driver_uid LEFT OUTER JOIN
                         P21.dbo.currency_line AS currency_line WITH (NOLOCK) ON currency_line.currency_line_uid = lc_driver_x_tran.currency_line_uid LEFT OUTER JOIN
                         P21.dbo.inv_loc AS inv_loc WITH (nolock) ON inv_loc.inv_mast_uid = m.inv_mast_uid AND inv_loc.location_id = inventory_receipts_hdr.location_id LEFT OUTER JOIN
                         P21.dbo.inventory_supplier AS Inventory_supplier WITH (NOLOCK) ON inv_loc.primary_supplier_id = Inventory_supplier.supplier_id AND inv_loc.inv_mast_uid = Inventory_supplier.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.code_p21 AS p WITH (nolock) ON lc_driver_x_tran.calculation_method_code_no = p.code_no