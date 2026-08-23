SELECT        TOP (100) PERCENT ol.order_no AS OrdNum, ol.line_no AS OrdLineNum, ol.company_no, CASE WHEN ol.disposition IS NULL OR
                         ol.disposition = ' ' THEN 'Blank' ELSE ol.disposition END AS Disposition, ol.product_group_id, ol.[assembly], COALESCE (ol.complete, 'N') AS Complete, CONVERT(datetime, CONVERT(char(10), ol.required_date, 120), 120) 
                         AS RequiredDate, CAST(COALESCE (ol.qty_ordered, 0) AS decimal(19, 4)) AS QtyOrd, CAST(COALESCE (ol.qty_allocated, 0) AS decimal(19, 4)) AS QtyAlloc, CAST(COALESCE (ol.qty_on_pick_tickets, 0) AS decimal(19, 4)) AS QtyPick,
                          CAST(COALESCE (ol.qty_invoiced, 0) AS decimal(19, 4)) AS QtyInv, CAST(COALESCE (ol.qty_canceled, 0) AS decimal(19, 4)) AS QtyCanceled, oh.company_id AS Company, oh.customer_id, oh.location_id, 
                         oh.customer_id AS CustId, oh.ship2_add1, oh.ship2_add2, oh.ship2_city, oh.ship2_state, oh.ship2_zip AS ship2_postal_code, oh.ship2_country, COALESCE (oh.projected_order, 'N') AS projected_order, 
                         COALESCE (oh.completed, 'N') AS HDRComplete, COALESCE (oh.rma_flag, 'N') AS RMA_Flag, COALESCE (oh.approved, 'Y') AS Apprvd, CONVERT(datetime, CONVERT(char(10), oh.date_created, 120), 120) AS hdrcreatedate, 
                         CONVERT(datetime, CONVERT(char(10), oh.expected_completion_date, 120), 120) AS Expected_Completion_Date, CONVERT(datetime, CONVERT(char(10), oh.promise_date, 120), 120) AS Promise_Date, CONVERT(datetime, 
                         CONVERT(char(10), oh.requested_ship_date, 120), 120) AS Requested_Ship_Date, CONVERT(datetime, CONVERT(char(10), oh.requested_date, 120), 120) AS Requested_Date, CONVERT(datetime, CONVERT(char(10), 
                         oh.order_date, 120), 120) AS OrdDate, YEAR(oh.order_date) AS CalendarYear, MONTH(oh.order_date) AS CalendarMonth, oe_hdr_salesrep.salesrep_id AS OrdSalesRepID, oe_hdr_salesrep.salesrep_id AS salesrepidorder, 
                         ol.item_id, vendor_supplier.vendor_id, location.default_branch_id AS branch_id, CAST(CASE WHEN qty_canceled <> 0 THEN (ol.qty_ordered - qty_canceled) 
                         * unit_price_home WHEN ol.disposition = 'b' THEN ol.qty_ordered / (COALESCE (pricing_unit_size, 1)) * unit_price_home ELSE extended_price_home END AS decimal(19, 4)) AS Sales, 
                         ol.sales_cost_home * ((ol.qty_ordered - ol.qty_canceled) / ol.pricing_unit_size) AS Cogs, ol.commission_cost_home * ((ol.qty_ordered - ol.qty_canceled) / ol.pricing_unit_size) AS ExtComCost, ol.qty_per_assembly, 
                         CAST(CASE WHEN qty_canceled <> 0 THEN (ol.qty_ordered - qty_canceled) * unit_price_home WHEN ol.disposition = 'b' THEN ol.qty_ordered / (COALESCE (pricing_unit_size, 1)) 
                         * unit_price_home ELSE extended_price_home END AS decimal(19, 4)) - ol.sales_cost_home * ((ol.qty_ordered - ol.qty_canceled) / ol.pricing_unit_size) AS GM, 
                         CAST(CASE WHEN qty_canceled <> 0 THEN (ol.qty_ordered - qty_canceled) * unit_price_home WHEN ol.disposition = 'b' THEN ol.qty_ordered / (COALESCE (pricing_unit_size, 1)) 
                         * unit_price_home ELSE extended_price_home END AS decimal(19, 4)) - ol.commission_cost_home * ((ol.qty_ordered - ol.qty_canceled) / ol.pricing_unit_size) AS GMComm, oe_line_qty.QtyOpen, 
                         ROUND(oe_line_qty.QtyOpen / ol.pricing_unit_size * ol.unit_price_home, 4) AS OpenSales, ROUND(oe_line_qty.QtyOpen / ol.pricing_unit_size * ol.sales_cost_home, 4) AS OpenCost, 
                         ROUND(oe_line_qty.QtyOpen / ol.pricing_unit_size * ol.unit_price_home, 4) - ROUND(oe_line_qty.QtyOpen / ol.pricing_unit_size * ol.sales_cost_home, 4) AS GMOpenMavg, 
                         ROUND(oe_line_qty.QtyOpen / ol.pricing_unit_size * ol.commission_cost_home, 4) AS OpenCostComm, DATEDIFF(dd, oh.order_date, GETDATE()) AS Days, 1 AS LineCount, 
                         CASE WHEN oe_line_qty.qtyopen > 0 THEN 1 ELSE 0 END AS openLineCount, CASE WHEN datediff(dd, required_date, getdate()) <= 0 THEN 0 ELSE DateDiff(dd, required_date, getdate()) END AS DaysLate
FROM            P21.dbo.p21_view_oe_hdr AS oh LEFT OUTER JOIN
                         P21.dbo.p21_view_oe_line AS ol WITH (nolock) ON ol.order_no = oh.order_no AND oh.oe_hdr_uid = ol.oe_hdr_uid LEFT OUTER JOIN
                         P21.dbo.location AS location WITH (nolock) ON location.delete_flag = 'n' AND oh.company_id = location.company_id AND oh.location_id = location.location_id LEFT OUTER JOIN
                         P21.dbo.inv_loc AS inv_loc WITH (nolock) ON inv_loc.location_id = ol.source_loc_id AND inv_loc.inv_mast_uid = ol.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.oe_hdr_salesrep AS oe_hdr_salesrep ON oh.order_no = oe_hdr_salesrep.order_number AND oe_hdr_salesrep.delete_flag = 'N' AND oe_hdr_salesrep.primary_salesrep = 'Y' LEFT OUTER JOIN
                             (SELECT        order_no, line_no, 
                                                         CAST(CASE WHEN oe_line.qty_ordered < 0 THEN oe_line.qty_ordered + oe_line.qty_canceled - oe_line.qty_invoiced ELSE CASE WHEN oe_line.qty_ordered + oe_line.qty_canceled - oe_line.qty_invoiced < 0 THEN
                                                          0 ELSE oe_line.qty_ordered - oe_line.qty_canceled - oe_line.qty_invoiced END END AS decimal(19, 4)) AS QtyOpen
                               FROM            P21.dbo.p21_view_oe_line AS oe_line) AS oe_line_qty ON ol.order_no = oe_line_qty.order_no AND ol.line_no = oe_line_qty.line_no LEFT OUTER JOIN
                         P21.dbo.inventory_supplier AS inventory_supplier WITH (nolock) ON inv_loc.primary_supplier_id = inventory_supplier.supplier_id AND inv_loc.inv_mast_uid = inventory_supplier.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.vendor_supplier AS vendor_supplier ON inv_loc.primary_supplier_id = vendor_supplier.supplier_id AND oh.company_id = vendor_supplier.company_id AND vendor_supplier.delete_flag = 'n' AND 
                         vendor_supplier.primary_vendor = 'y'
WHERE        (COALESCE (oh.approved, 'Y') = 'Y') AND (COALESCE (oh.delete_flag, 'N') = 'N') AND (COALESCE (oh.cancel_flag, 'N') = 'N') AND (COALESCE (ol.delete_flag, 'N') = 'N') AND (ol.qty_per_assembly = 0) AND 
                         (oh.completed NOT IN ('y', 't')) AND (oh.projected_order <> 'y')