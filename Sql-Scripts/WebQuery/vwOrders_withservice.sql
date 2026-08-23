SELECT        customer.legacy_id AS customer_legacy_id, oh.packing_basis, ol.parent_oe_line_uid, ol.job_price_line_uid, ol.order_no AS OrdNum, ol.line_no AS OrdLineNum, ol.company_no, ol.other_charge AS OthCharge, 
                         ol.extended_desc AS ExtDesc, ol.customer_part_number AS CustItemNum, ol.inv_mast_uid AS InvenMastId, ol.last_maintained_by AS LastModBy, ol.unit_of_measure AS UOM, ol.sales_tax AS SalesTax, ol.tax_item AS TaxItem,
                          ol.product_group_id, ol.product_group_id AS ProdGroup, ol.[assembly], ol.purchase_class_id AS PurchClass, ol.shipping_route_uid AS ShipRoute, ol.commission_cost_edited, ol.other_cost_edited, ol.order_cost_edited, 
                         ol.ship_loc_id AS ShipLocation, ol.supplier_id AS SupplierID, ol.manual_price_overide, ISNULL(ol.complete, 'N') AS Complete, CONVERT(DATETIME, CONVERT(CHAR(10), ol.date_created, 120), 120) AS LineDateCreated, 
                         CONVERT(DATETIME, CONVERT(CHAR(10), ol.date_created, 120), 120) AS CreateDate, CONVERT(DATETIME, CONVERT(CHAR(10), ol.date_last_modified, 120), 120) AS LastModDate, CONVERT(DATETIME, CONVERT(CHAR(10), 
                         ol.required_date, 120), 120) AS RequiredDate, CONVERT(DATETIME, CONVERT(CHAR(10), ol.pick_date, 120), 120) AS PickDate, COALESCE (l.hours_worked, COALESCE (CASE WHEN ols.release_qty = 0 AND 
                         ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0), 0) AS QtyOrd, ISNULL(ol.qty_allocated, 0) AS QtyAlloc, COALESCE (ols.qty_picked, ol.qty_on_pick_tickets, 0) AS QtyPick, 
                         COALESCE (ols.qty_invoiced, ol.qty_invoiced, 0) AS QtyInv, COALESCE (ols.qty_canceled, ol.qty_canceled, 0) AS QtyCanceled, oe_line_qty.QtyOpen + (CASE WHEN s.row_status_flag NOT IN (976, 1735) 
                         THEN hours_worked ELSE 0 END) AS qtyopen, ISNULL(ol.unit_quantity, 0) AS UnitQty, ISNULL(ol.unit_size, 0) AS UnitSize, ol.pricing_unit_size AS PricingUnitSize, ISNULL(ol.unit_price_home, 0) AS UnitPrice, 
                         ISNULL(ol.base_ut_price, 0) AS ListPrice, ISNULL(ol.sales_cost_home, 0) AS sales_cost, ISNULL(ol.po_cost_home, 0) AS POcost, ISNULL(ol.other_cost_home, 0) AS OtherCost, ISNULL(l.sales_cost / l.hours_worked, 
                         ol.sales_cost_home) AS UnitCost, COALESCE (l.commission_cost / l.hours_worked, ol.commission_cost_home, 0) AS UnitComCost, ol.system_calc_unit_price, ol.qty_per_assembly, ol.oe_line_uid, 
                         CASE WHEN round(ol.system_calc_unit_price, 2) = round(ol.unit_price_home, 2) THEN 'Y' ELSE 'N' END AS Price_flag, CASE WHEN isnull(ols.disposition, ol.disposition) IS NULL OR
                         isnull(ols.disposition, ol.disposition) = ' ' THEN 'Blank' ELSE isnull(ols.disposition, ol.disposition) END AS Disposition, oh.original_promise_date, oh.created_by, oh.company_id AS Company, CAST(MONTH(oh.order_date) 
                         AS VARCHAR(2)) + '/' + CAST(YEAR(oh.order_date) AS VARCHAR(4)) AS order_period, oh.customer_id, oh.ship2_name AS ShipToName, oh.location_id AS LocationID, oh.location_id, oh.customer_id AS CustId, oh.contact_id, 
                         oh.carrier_id AS CarrierId, oh.terms, oh.po_no AS PO, oh.address_id AS ship_to_id, ISNULL(oh.corp_address_id, oh.customer_id) AS corp_address_id, oh.validation_status, oh.taker, oh.job_name AS JobName, 
                         oh.will_call AS WillCall, oh.front_counter AS Counter, oh.source_code_no AS SourceCode, oh.ship2_add1, oh.ship2_add2, oh.ship2_city, oh.ship2_state, oh.ship2_zip, oh.ship2_country, oh.cancel_flag, 
                         ISNULL(oh.projected_order, 'N') AS projected_order, ISNULL(oh.completed, 'N') AS HDRComplete, ISNULL(oh.rma_flag, 'N') AS RMA_Flag, ISNULL(oh.approved, 'Y') AS Apprvd, CONVERT(DATETIME, CONVERT(CHAR(10), 
                         oh.date_created, 120), 120) AS hdrcreatedate, CONVERT(DATETIME, CONVERT(CHAR(10), oh.expected_completion_date, 120), 120) AS Expected_Completion_Date, CONVERT(DATETIME, CONVERT(CHAR(10), oh.promise_date, 
                         120), 120) AS Promise_Date, CONVERT(DATETIME, CONVERT(CHAR(10), oh.requested_ship_date, 120), 120) AS Requested_Ship_Date, CONVERT(DATETIME, CONVERT(CHAR(10), oh.requested_date, 120), 120) 
                         AS Requested_Date, CONVERT(DATETIME, CONVERT(CHAR(10), oh.order_date, 120), 120) AS OrdDate, CONVERT(DATETIME, CONVERT(CHAR(10), oh.date_last_modified, 120), 120) AS last_modified_date_hdr, 
                         YEAR(oh.order_date) AS CalendarYear, MONTH(oh.order_date) AS CalendarMonth, ISNULL(oe_hdr_class.class_description, 'Blank') AS oe_hdr_class1, ISNULL(oe_hdr_class2.class_description, 'Blank') AS oe_hdr_class2, 
                         ISNULL(oe_hdr_class3.class_description, 'Blank') AS oe_hdr_class3, ISNULL(oe_hdr_class4.class_description, 'Blank') AS oe_hdr_class4, ISNULL(oe_hdr_class5.class_description, 'Blank') AS oe_hdr_class5, 
                         ISNULL(imclass.class_description, 'Blank') AS IMClass1, ISNULL(imCLass2.class_description, 'Blank') AS IMClass2, ISNULL(imCLass3.class_description, 'Blank') AS IMClass3, ISNULL(imCLass4.class_description, 'Blank') 
                         AS IMClass4, ISNULL(imCLass5.class_description, 'Blank') AS IMClass5, ISNULL(class.class_description, 'Blank') AS CustClass1, ISNULL(CLass2.class_description, 'Blank') AS CustClass2, ISNULL(CLass3.class_description, 
                         'Blank') AS CustClass3, ISNULL(CLass4.class_description, 'Blank') AS CustClass4, ISNULL(CLass5.class_description, 'Blank') AS CustClass5, ISNULL(sh_class1.class_description, 'Blank') AS Ship_Class_1, 
                         ISNULL(sh_class2.class_description, 'Blank') AS Ship_Class_2, ISNULL(sh_class3.class_description, 'Blank') AS Ship_Class_3, ISNULL(sh_class4.class_description, 'Blank') AS Ship_Class_4, 
                         ISNULL(sh_class5.class_description, 'Blank') AS Ship_Class_5, oe_hdr_salesrep.salesrep_id AS OrdSalesRepID, oe_hdr_salesrep.salesrep_id AS salesrepidorder, im.item_id AS ItemId, im.item_id, im.item_desc AS ItemDesc, 
                         addr.name AS CustName, customer.salesrep_id AS CustSalesRepID, CONVERT(DATETIME, CONVERT(CHAR(10), customer.date_created, 120), 120) AS CustDateCreated, customer.other_exemption_number, 
                         contacts_2.last_name + ', ' + contacts_2.first_name AS CustSalesRepName, contacts_1.last_name + ', ' + contacts_1.first_name AS OrdSalesRepName, contacts.last_name + ', ' + contacts.first_name AS ContactName, 
                         contacts.direct_phone, contacts.phone_ext, contactsShip.last_name + ', ' + contactsShip.first_name AS ShipSalesRepName, inv_loc.price1 AS LocationPrice1, inv_loc.price2 AS LocationPrice2, inv_loc.price3 AS LocationPrice3, 
                         inv_loc.price4 AS LocationPrice4, inv_loc.price5 AS LocationPrice5, inv_loc.price6 AS LocationPrice6, inv_loc.price7 AS LocationPrice7, inv_loc.price8 AS LocationPrice8, inv_loc.price9 AS LocationPrice9, 
                         inv_loc.price10 AS LocationPrice10, inv_loc.qty_on_hand, inv_loc.order_quantity AS po_qty, inv_loc.stockable, l.hours_worked, l.hours_charged, s.oe_line_service_uid, ISNULL(ols.release_no, 0) AS release_no, 
                         ISNULL(ols.printed, 'Blank') AS release_printed, CONVERT(DATETIME, CONVERT(CHAR(10), ols.release_date, 120), 120) AS release_date, CONVERT(DATETIME, CONVERT(CHAR(10), ols.pick_date, 120), 120) 
                         AS release_pick_date, ols.release_qty, ols.release_status_flag, su.buyer_id, location.default_branch_id AS branch_id, vendor_supplier.vendor_id, vendor.vendor_name, pg.product_group_desc AS ProdGroupDesc, 
                         su.supplier_name AS SupplierName, location.location_name AS LocationName, branch.branch_description AS BranchName, location.default_branch_id AS BranchID, ship_to_salesrep.salesrep_id AS SalesRepIDShip, 
                         Price_page.description AS PricePageDescription, inventory_supplier.supplier_part_no, company.company_name, Terms.terms_desc, SourceCode.code_description AS source_code_noDesc, shipping_route.route_description, 
                         freight_code.freight_desc, Shiplocation.location_name AS ShipLocationName, address_carrier.name AS CarrierName, ISNULL(corp.address_name, customer.customer_name) AS CorpAddName, 
                         tech.first_name + ' ' + tech.last_name AS Tech_name, CASE WHEN s.oe_line_uid IS NOT NULL THEN 'Y' ELSE 'N' END AS isservice, ISNULL(order_type.code_description, 'Blank') AS order_type, 
                         CASE WHEN isnull(ols.disposition, ol.disposition) = 'T' THEN 'Transfer' WHEN isnull(ols.disposition, ol.disposition) = '' OR
                         isnull(ols.disposition, ol.disposition) IS NULL THEN 'Blank' ELSE d .code_description END AS disposition_Desc, DATEDIFF(dd, oh.order_date, GETDATE()) AS Days, 1.00 AS LineCount, 
                         CASE WHEN oe_line_qty.qtyopen > 0 THEN 1 ELSE 0 END AS openLineCount, CASE WHEN datediff(dd, required_date, getdate()) <= 0 THEN 0 ELSE DateDiff(dd, required_date, getdate()) END AS DaysLate, 
                         l.extended_price AS service_extended_price, ISNULL(l.extended_price, (COALESCE (CASE WHEN ols.release_qty = 0 AND 
                         ol.qty_ordered <> 0 THEN ol.unit_quantity ELSE release_qty * CASE WHEN ol.qty_ordered - ol.qty_canceled = 0 THEN 0 ELSE unit_quantity / ol.qty_ordered - ol.qty_canceled END END, ol.unit_quantity, 0) 
                         - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) / ISNULL(ol.pricing_unit_size, 1) * ol.unit_price_home) AS sales, ol.unit_price_home, ol.pricing_unit_size, ol.unit_quantity, CASE WHEN s.oe_line_uid IS NOT NULL AND 
                         ol.complete = 'n' AND s.row_status_flag NOT IN (976, 1735) THEN isnull(l.extended_price, 0) ELSE CASE WHEN (COALESCE (CASE WHEN ols.release_qty = 0 AND 
                         ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) / (COALESCE (pricing_unit_size, 1))) * unit_price_home = 0 THEN 0 ELSE (oe_line_qty.qtyopen / ol.pricing_unit_size) 
                         * unit_price_home END END AS OpenSales, l.estimated_cost * l.hours_worked AS service_cogs, CASE WHEN isnull(ols.disposition, ol.disposition) = 'c' THEN 0 ELSE isnull(l.estimated_cost * hours_worked, 
                         CASE WHEN isnull(ols.disposition, ol.disposition) IN ('b', 's', 'd') 
                         THEN CASE WHEN po_cost_home = 0 THEN other_cost_home ELSE po_cost_home END ELSE ol.sales_Cost_home END * ((COALESCE (CASE WHEN ols.release_qty = 0 AND 
                         ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) / isnull(pricing_unit_size, 1))) END AS cogs_estimated, ISNULL(l.extended_price, 
                         (COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) / ISNULL(ol.pricing_unit_size, 1) 
                         * ol.unit_price_home) - CASE WHEN isnull(ols.disposition, ol.disposition) = 'c' THEN 0 ELSE isnull(l.estimated_cost * hours_worked, CASE WHEN isnull(ols.disposition, ol.disposition) IN ('b', 's', 'd') 
                         THEN CASE WHEN po_cost_home = 0 THEN other_cost_home ELSE po_cost_home END ELSE ol.sales_Cost_home END * ((COALESCE (CASE WHEN ols.release_qty = 0 AND 
                         ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) / isnull(pricing_unit_size, 1))) END AS GM_estimated, COALESCE (l.commission_cost, 
                         ol.commission_cost_home * ((COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) 
                         / ol.pricing_unit_size)) AS extended_commission_cost, ISNULL(l.extended_price, (COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) 
                         - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) / ISNULL(ol.pricing_unit_size, 1) * ol.unit_price_home) - COALESCE (l.commission_cost, ol.commission_cost_home * ((COALESCE (CASE WHEN ols.release_qty = 0 AND 
                         ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) / ol.pricing_unit_size)) AS GMComm, COALESCE (l.hours_worked * ol.other_cost, 
                         ol.other_cost * ((COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) 
                         / ol.pricing_unit_size)) AS extended_other_cogs, COALESCE (l.hours_worked * ol.po_cost, ol.po_cost * ((COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, 
                         ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) / ol.pricing_unit_size)) AS extended_po_cogs, COALESCE (l.hours_worked * ol.sales_cost_home, 
                         ol.sales_cost_home * ((COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0)) 
                         / ol.pricing_unit_size)) AS extended_order_cogs, CASE WHEN contactsShip.id IN
                             (SELECT DISTINCT sales_manager_id
                               FROM            p21.dbo.contacts
                               WHERE        salesrep = 'y' AND delete_flag = 'n' AND sales_manager_id IS NOT NULL) 
                         THEN contactsShip.last_name + ', ' + contactsShip.first_name ELSE manager.last_name + ', ' + manager.first_name END AS Sales_Manager, ISNULL(bdt.Business_day_of_month, bdl.Business_day_of_month) 
                         AS business_day_of_month, v.qty_on_vessel, iud.legacy_item_id, iud.legacy_item_description, oh.po_no_append
FROM            P21.dbo.p21_view_oe_hdr AS oh WITH (NOLOCK) LEFT OUTER JOIN
                         P21.dbo.p21_view_oe_line AS ol WITH (NOLOCK) ON ol.order_no = oh.order_no AND oh.oe_hdr_uid = ol.oe_hdr_uid LEFT OUTER JOIN
                         P21.dbo.company AS company ON oh.company_id = company.company_id AND company.delete_flag <> 'y' LEFT OUTER JOIN
                         P21.dbo.address AS addr WITH (NOLOCK) ON addr.id = oh.customer_id LEFT OUTER JOIN
                         P21.dbo.corp_id AS corp WITH (NOLOCK) ON corp.address_id = oh.corp_address_id AND corp.company_id = oh.company_id LEFT OUTER JOIN
                         P21.dbo.contacts AS contacts WITH (NOLOCK) ON oh.contact_id = contacts.id LEFT OUTER JOIN
                         P21.dbo.location AS location WITH (NOLOCK) ON location.delete_flag = 'n' AND oh.company_id = location.company_id AND location.location_id = oh.source_location_id LEFT OUTER JOIN
                         P21.dbo.branch AS branch WITH (NOLOCK) ON location.default_branch_id = branch.branch_id AND location.company_id = branch.company_id LEFT OUTER JOIN
                         P21.dbo.inv_loc AS inv_loc WITH (NOLOCK) ON inv_loc.location_id = ol.source_loc_id AND inv_loc.inv_mast_uid = ol.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.product_group AS pg WITH (NOLOCK) ON pg.company_id = ol.company_no AND pg.product_group_id = ol.product_group_id LEFT OUTER JOIN
                         P21.dbo.supplier AS su WITH (NOLOCK) ON ol.supplier_id = su.supplier_id LEFT OUTER JOIN
                         P21.dbo.inv_mast AS im WITH (NOLOCK) ON ol.inv_mast_uid = im.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.inv_mast_ud AS iud WITH (nolock) ON iud.inv_mast_uid = im.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.oe_hdr_salesrep AS oe_hdr_salesrep WITH (NOLOCK) ON oh.order_no = oe_hdr_salesrep.order_number AND oe_hdr_salesrep.delete_flag = 'N' AND oe_hdr_salesrep.primary_salesrep = 'Y' LEFT OUTER JOIN
                         P21.dbo.contacts AS contacts_1 WITH (NOLOCK) ON contacts_1.id = oe_hdr_salesrep.salesrep_id LEFT OUTER JOIN
                         P21.dbo.customer AS customer WITH (NOLOCK) ON oh.customer_id = customer.customer_id AND oh.company_id = customer.company_id LEFT OUTER JOIN
                         P21.dbo.contacts AS contacts_2 WITH (NOLOCK) ON customer.salesrep_id = contacts_2.id LEFT OUTER JOIN
                         P21.dbo.class AS class WITH (NOLOCK) ON customer.class_1id = class.class_id AND class.class_number = 1 AND class.class_type = 'cs' AND class.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass2 WITH (NOLOCK) ON customer.class_2id = CLass2.class_id AND CLass2.class_number = 2 AND CLass2.class_type = 'cs' AND CLass2.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass3 WITH (NOLOCK) ON customer.class_3id = CLass3.class_id AND CLass3.class_number = 3 AND CLass3.class_type = 'cs' AND CLass3.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass4 WITH (NOLOCK) ON customer.class_4id = CLass4.class_id AND CLass4.class_number = 4 AND CLass4.class_type = 'cs' AND CLass4.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS CLass5 WITH (NOLOCK) ON customer.class_5id = CLass5.class_id AND CLass5.class_number = 5 AND CLass5.class_type = 'cs' AND CLass5.delete_flag = 'n' LEFT OUTER JOIN
                             (SELECT        order_no, line_no, SUM(release_qty) AS scheduled_qty
                               FROM            P21.dbo.oe_line_schedule AS ols
                               GROUP BY order_no, line_no) AS sc ON ol.order_no = sc.order_no AND ol.line_no = sc.line_no LEFT OUTER JOIN
                         P21.dbo.oe_line_schedule AS ols ON ols.order_no = ol.order_no AND ols.line_no = ol.line_no AND ols.order_no NOT IN (1000446) AND sc.scheduled_qty = ol.qty_ordered LEFT OUTER JOIN
                             (SELECT        ol.order_no, ol.line_no, ISNULL(ols.release_no, 0) AS release_no, CASE WHEN COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, 
                                                         ol.qty_ordered, 0) < 0 THEN COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) + COALESCE (ols.qty_canceled, 
                                                         ol.qty_canceled, 0) - COALESCE (ols.qty_invoiced, ol.qty_invoiced, 0) ELSE CASE WHEN COALESCE (CASE WHEN ols.release_qty = 0 AND ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, 
                                                         ol.qty_ordered, 0) + COALESCE (ols.qty_canceled, ol.qty_canceled, 0) - COALESCE (ols.qty_invoiced, ol.qty_invoiced, 0) < 0 THEN 0 ELSE COALESCE (CASE WHEN ols.release_qty = 0 AND 
                                                         ol.qty_ordered <> 0 THEN ol.qty_ordered ELSE ols.release_qty END, ol.qty_ordered, 0) - COALESCE (ols.qty_canceled, ol.qty_canceled, 0) - COALESCE (ols.qty_invoiced, ol.qty_invoiced, 0) 
                                                         END END AS QtyOpen
                               FROM            P21.dbo.p21_view_oe_line AS ol LEFT OUTER JOIN
                                                         P21.dbo.oe_line_schedule AS ols ON ols.order_no = ol.order_no AND ols.line_no = ol.line_no) AS oe_line_qty ON ol.order_no = oe_line_qty.order_no AND ol.line_no = oe_line_qty.line_no AND 
                         ISNULL(ols.release_no, 0) = oe_line_qty.release_no LEFT OUTER JOIN
                         P21.dbo.class AS oe_hdr_class WITH (NOLOCK) ON oh.class_1id = oe_hdr_class.class_id AND oe_hdr_class.class_number = 1 AND oe_hdr_class.class_type = 'oe' AND oe_hdr_class.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS oe_hdr_class2 WITH (NOLOCK) ON oh.class_2id = oe_hdr_class2.class_id AND oe_hdr_class2.class_number = 2 AND oe_hdr_class2.class_type = 'oe' AND oe_hdr_class2.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS oe_hdr_class3 WITH (NOLOCK) ON oh.class_3id = oe_hdr_class3.class_id AND oe_hdr_class3.class_number = 3 AND oe_hdr_class3.class_type = 'oe' AND oe_hdr_class3.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS oe_hdr_class4 WITH (NOLOCK) ON oh.class_4id = oe_hdr_class4.class_id AND oe_hdr_class4.class_number = 4 AND oe_hdr_class4.class_type = 'oe' AND oe_hdr_class4.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS oe_hdr_class5 WITH (NOLOCK) ON oh.class_5id = oe_hdr_class5.class_id AND oe_hdr_class5.class_number = 5 AND oe_hdr_class5.class_type = 'oe' AND oe_hdr_class5.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.ship_to_salesrep AS ship_to_salesrep WITH (NOLOCK) ON ship_to_salesrep.ship_to_id = oh.address_id AND ship_to_salesrep.company_id = oh.company_id AND ship_to_salesrep.primary_salesrep = 'y' AND 
                         ship_to_salesrep.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.contacts AS contactsShip WITH (NOLOCK) ON contactsShip.id = ship_to_salesrep.salesrep_id LEFT OUTER JOIN
                         P21.dbo.contacts AS manager WITH (nolock) ON manager.id = contactsShip.sales_manager_id LEFT OUTER JOIN
                         P21.dbo.price_page AS Price_page WITH (NOLOCK) ON Price_page.price_page_uid = ol.price_page_uid LEFT OUTER JOIN
                         P21.dbo.inventory_supplier AS inventory_supplier WITH (NOLOCK) ON inv_loc.primary_supplier_id = inventory_supplier.supplier_id AND inv_loc.inv_mast_uid = inventory_supplier.inv_mast_uid LEFT OUTER JOIN
                         P21.dbo.class AS imclass WITH (NOLOCK) ON im.class_id1 = imclass.class_id AND imclass.class_number = 1 AND imclass.class_type = 'iv' AND imclass.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS imCLass2 WITH (NOLOCK) ON im.class_id2 = imCLass2.class_id AND imCLass2.class_number = 2 AND imCLass2.class_type = 'iv' AND imCLass2.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS imCLass3 WITH (NOLOCK) ON im.class_id3 = imCLass3.class_id AND imCLass3.class_number = 3 AND imCLass3.class_type = 'iv' AND imCLass3.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS imCLass4 WITH (NOLOCK) ON im.class_id4 = imCLass4.class_id AND imCLass4.class_number = 4 AND imCLass4.class_type = 'iv' AND imCLass4.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS imCLass5 WITH (NOLOCK) ON im.class_id5 = imCLass5.class_id AND imCLass5.class_number = 5 AND imCLass5.class_type = 'iv' AND imCLass5.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.terms AS Terms WITH (NOLOCK) ON oh.terms = Terms.terms_id AND Terms.delete_flag <> 'y' LEFT OUTER JOIN
                         P21.dbo.code_p21 AS SourceCode WITH (NOLOCK) ON oh.source_code_no = SourceCode.code_no AND SourceCode.row_status_flag = 'A' LEFT OUTER JOIN
                         P21.dbo.freight_code AS freight_code WITH (NOLOCK) ON freight_code.freight_code_uid = oh.freight_code_uid AND freight_code.company_id = oh.company_id LEFT OUTER JOIN
                         P21.dbo.shipping_route AS shipping_route WITH (NOLOCK) ON shipping_route.shipping_route_uid = oh.shipping_route_uid LEFT OUTER JOIN
                         P21.dbo.location AS Shiplocation WITH (NOLOCK) ON location.delete_flag = 'n' AND oh.company_id = location.company_id AND ol.ship_loc_id = Shiplocation.location_id LEFT OUTER JOIN
                         P21.dbo.address AS address_carrier WITH (NOLOCK) ON oh.carrier_id = address_carrier.id AND address_carrier.delete_flag <> 'y' LEFT OUTER JOIN
                         P21.dbo.vendor_supplier AS vendor_supplier WITH (NOLOCK) ON inv_loc.primary_supplier_id = vendor_supplier.supplier_id AND oh.company_id = vendor_supplier.company_id AND vendor_supplier.delete_flag = 'n' AND 
                         vendor_supplier.primary_vendor = 'y' LEFT OUTER JOIN
                         P21.dbo.vendor AS vendor WITH (NOLOCK) ON vendor.vendor_id = vendor_supplier.vendor_id AND oh.company_id = vendor.company_id LEFT OUTER JOIN
                         P21.dbo.ship_to AS ship_to WITH (NOLOCK) ON ship_to.ship_to_id = oh.address_id AND ship_to.company_id = oh.company_id LEFT OUTER JOIN
                         P21.dbo.class AS sh_class1 WITH (NOLOCK) ON ship_to.class1_id = sh_class1.class_id AND sh_class1.class_number = 1 AND sh_class1.class_type = 'cs' AND sh_class1.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS sh_class2 WITH (NOLOCK) ON ship_to.class2_id = sh_class2.class_id AND sh_class2.class_number = 2 AND sh_class2.class_type = 'cs' AND sh_class2.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS sh_class3 WITH (NOLOCK) ON ship_to.class3_id = sh_class3.class_id AND sh_class3.class_number = 3 AND sh_class3.class_type = 'cs' AND sh_class3.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS sh_class4 WITH (NOLOCK) ON ship_to.class4_id = sh_class4.class_id AND sh_class4.class_number = 4 AND sh_class4.class_type = 'cs' AND sh_class4.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS sh_class5 WITH (NOLOCK) ON ship_to.class5_id = sh_class5.class_id AND sh_class5.class_number = 5 AND sh_class5.class_type = 'cs' AND sh_class5.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.oe_line_service AS s WITH (NOLOCK) ON s.oe_line_uid = ol.oe_line_uid LEFT OUTER JOIN
                         P21.dbo.oe_line_service_labor AS l WITH (NOLOCK) ON s.oe_line_service_uid = l.oe_line_service_uid LEFT OUTER JOIN
                             (SELECT        code_sub_description, code_description
                               FROM            P21.dbo.code_p21
                               WHERE        (code_no IN
                                                             (SELECT        code_no
                                                               FROM            P21.dbo.code_x_code_group_p21
                                                               WHERE        (code_group_no IN (1179))))) AS d ON d.code_sub_description = ISNULL(ols.disposition, ol.disposition) LEFT OUTER JOIN
                         P21.dbo.code_p21 AS order_type WITH (NOLOCK) ON order_type.code_no = oh.order_type LEFT OUTER JOIN
                         P21.dbo.service_technician AS service_technician WITH (NOLOCK) ON l.service_technician_uid = service_technician.service_technician_uid LEFT OUTER JOIN
                         P21.dbo.contacts AS tech WITH (NOLOCK) ON tech.id = service_technician.contacts_id LEFT OUTER JOIN
                         dbo.Business_days_LY AS bdl ON bdl.Day_LY = CONVERT(datetime, CONVERT(char(10), oh.order_date, 120), 120) LEFT OUTER JOIN
                         dbo.Business_days_TY AS bdt ON bdt.Day_TY = CONVERT(datetime, CONVERT(char(10), oh.order_date, 120), 120) LEFT OUTER JOIN
                             (SELECT        po_line.inv_mast_uid, vessel_receipts_hdr.location_id, SUM(CAST(vessel_receipts_line.container_qty_received AS int) - vessel_receipts_line.container_qty_unloaded) AS qty_on_vessel
                               FROM            P21.dbo.vessel_receipts_line AS vessel_receipts_line LEFT OUTER JOIN
                                                         P21.dbo.po_line AS po_line WITH (NOLOCK) ON vessel_receipts_line.po_line_uid = po_line.po_line_uid AND po_line.complete <> 'y' LEFT OUTER JOIN
                                                         P21.dbo.vessel_receipts_hdr AS vessel_receipts_hdr WITH (NOLOCK) ON vessel_receipts_line.vessel_receipts_hdr_uid = vessel_receipts_hdr.vessel_receipts_hdr_uid
                               WHERE        (vessel_receipts_line.row_status_flag NOT IN (701, 976))
                               GROUP BY po_line.inv_mast_uid, vessel_receipts_hdr.location_id) AS v ON v.inv_mast_uid = ol.inv_mast_uid AND v.location_id = oh.location_id
WHERE        (ISNULL(oh.delete_flag, 'N') = 'N') AND (ISNULL(ol.delete_flag, 'N') = 'N') AND (ISNULL(oh.projected_order, 'N') <> 'y') AND (ISNULL(ol.qty_per_assembly, 0) = 0)