SELECT        inv_mast.item_id[SIMG],oe_hdr.po_no_append, customer.legacy_id AS customer_legacy_id, mc.manufacturing_class_desc, supplier_ud.legacy_id, supplier_ud.legacy_company, LEFT(invoice_line.gl_revenue_account_no, 5) AS GL_Rev_Acct, 
                         SUBSTRING(invoice_line.gl_revenue_account_no, 6, 3) AS GL_Rev_Segment, RIGHT(invoice_line.gl_revenue_account_no, 3) AS GL_REv_branch, invoice_hdr.company_no, invoice_hdr.bill2_name, invoice_hdr.customer_id, 
                         invoice_hdr.period, invoice_hdr.year_for_period, invoice_hdr.invoice_adjustment_type, invoice_hdr.original_document_type, invoice_hdr.po_no, invoice_hdr.invoice_no, invoice_hdr.order_no, invoice_hdr.ship2_address1, 
                         invoice_hdr.ship2_address2, invoice_hdr.ship2_city, invoice_hdr.ship2_state, invoice_hdr.ship2_postal_code, invoice_hdr.ship_to_id, invoice_hdr.ship2_name, invoice_hdr.ship2_contact, invoice_hdr.terms_desc, 
                         CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120) AS InvoiceDate, CONVERT(datetime, CONVERT(char(10), invoice_hdr.date_created, 120), 120) AS DateCreated, CONVERT(datetime, CONVERT(char(10), 
                         invoice_hdr.order_date, 120), 120) AS OrderDate, CONVERT(datetime, CONVERT(char(10), invoice_hdr.ship_date, 120), 120) AS ShipDate, invoice_hdr.branch_id, invoice_line.oe_line_number, invoice_line.exceptional_sales, 
                         COALESCE (invoice_line.sales_cost_home, oe_line.sales_cost) AS sales_Cost, invoice_hdr.invoice_class, invoice_hdr.invoice_type, invoice_hdr.bill2_contact, invoice_hdr.bill2_address1, invoice_hdr.bill2_address2, 
                         invoice_hdr.bill2_city, invoice_hdr.bill2_state, invoice_hdr.bill2_postal_code, invoice_hdr.carrier_name, invoice_hdr.sales_location_id, invoice_hdr.sales_location_id AS location_id, invoice_hdr.printed_date, 
                         ISNULL(invoice_hdr.corp_address_id, invoice_hdr.customer_id) AS corp_address_id, invoice_line.job_price_line_uid, invoice_line.customer_part_number, invoice_line.gl_inventory, invoice_line.gl_revenue_account_no, 
                         invoice_line.inv_mast_uid, invoice_line.invoice_line_uid, invoice_line.invoice_line_type, invoice_line.gl_cogs, invoice_line.item_id, invoice_line.other_charge_item, COALESCE (invoice_line.product_group_id, 
                         oe_line.product_group_id, inv_loc.product_group_id, 'Blank') AS product_group_id, invoice_line.tax_item, invoice_line.line_no AS InvoiceLineNo, invoice_line.unit_of_measure, invoice_line.supplier_id, 
                         invoice_line.gl_salse_tax_account_no, invoice_line.pricing_unit_size, invoice_line.invoice_line_uid_parent, CONVERT(datetime, CONVERT(char(10), invoice_line.date_last_modified, 120), 120) AS LineChangeDate, 
                         invoice_line.qty_requested, CAST(invoice_line.commission_cost_home AS decimal(19, 4)) AS commission_cost, CAST(invoice_line.unit_price_home AS decimal(19, 4)) AS Unit_Price, 
                         CAST(invoice_line.other_cost_home AS decimal(19, 4)) AS Other_Cost, invoice_line.pricing_unit, invoice_line.net_quantity, invoice_line.pricing_quantity, invoice_line.job_id, invoice_line.sales_unit_size, invoice_line.list_price, 
                         COALESCE (invoice_line.qty_backordered, 0) AS qty_backordered, CASE COALESCE (item_uom.unit_size, invoice_line.sales_unit_size, 1) WHEN 0 THEN 0 WHEN NULL 
                         THEN 0 ELSE invoice_line.qty_shipped / COALESCE (item_uom.unit_size, invoice_line.sales_unit_size, 1) END AS qty_shipped, CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN CASE COALESCE (item_uom.unit_size, 
                         invoice_line.sales_unit_size, 1) WHEN 0 THEN 0 WHEN NULL THEN 0 ELSE invoice_line.qty_shipped / COALESCE (item_uom.unit_size, invoice_line.sales_unit_size, 1) END * COALESCE (item_uom.unit_size, 
                         invoice_line.sales_unit_size, 1) ELSE 0.00 END AS qty_shipped_in_units, CASE WHEN invoice_line_type IN (930, 929, 928, 982, 981) 
                         THEN 0 ELSE CAST(invoice_line.qty_shipped * invoice_line.commission_cost_home AS decimal(19, 4)) END AS ExtComCogs, CASE WHEN invoice_line_type IN (930, 929, 928, 982, 981) 
                         THEN 0 ELSE CAST(invoice_line.cogs_amount_home AS decimal(19, 4)) END AS Cogs_Amount, CASE WHEN invoice_line_type IN (930, 929, 928, 982, 981) THEN 0 ELSE CAST(CASE COALESCE (oe_line.pricing_option, 0) 
                         WHEN 1 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN 0 ELSE invoice_line.extended_price_home END) 
                         WHEN 2 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN invoice_line.extended_price_home ELSE 0 END) 
                         WHEN 3 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN invoice_line.extended_price_home ELSE 0 END) 
                         WHEN 4 THEN 0 ELSE invoice_line.extended_price_home END - invoice_line.qty_shipped * invoice_line.commission_cost_home AS decimal(19, 4)) END AS GMComm, CASE WHEN invoice_line_type IN (930, 929, 928, 982, 
                         981) THEN 0 ELSE CAST(CASE COALESCE (oe_line.pricing_option, 0) WHEN 1 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN 0 ELSE invoice_line.extended_price_home END) 
                         WHEN 2 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN invoice_line.extended_price_home ELSE 0 END) 
                         WHEN 3 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN invoice_line.extended_price_home ELSE 0 END) 
                         WHEN 4 THEN 0 ELSE invoice_line.extended_price_home END - invoice_line.cogs_amount_home AS decimal(19, 4)) END AS GMMavg, CASE WHEN invoice_line_type IN (930, 929, 928, 982, 981) 
                         THEN 0 ELSE CASE COALESCE (oe_line.pricing_option, 0) WHEN 1 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN 0 ELSE invoice_line.extended_price_home END) 
                         WHEN 2 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN invoice_line.extended_price_home ELSE 0 END) 
                         WHEN 3 THEN (CASE invoice_line.invoice_line_uid_parent WHEN 0 THEN invoice_line.extended_price_home ELSE 0 END) WHEN 4 THEN 0 ELSE invoice_line.extended_price_home END END AS Extended_Price, 
                         CASE WHEN invoice_line_type IN (929, 928) THEN extended_price_home ELSE 0 END AS Freight, CASE WHEN invoice_line_type IN (930) THEN extended_price_home ELSE 0 END AS Tax, customer.class_1id, 
                         customer.salesrep_id AS SalesRepIDCust, customer.customer_name, customer.sic_code, customer.class_2id, CONVERT(datetime, CONVERT(char(10), customer.date_created, 120), 120) AS CustDateCreated, 
                         contacts2.last_name + ', ' + contacts2.first_name AS SalesRepCust, contacts.last_name + ', ' + contacts.first_name AS SalesRepOrder, contactsShip.last_name + ', ' + contactsShip.first_name AS SalesRepShip, oe_hdr.taker, 
                         oe_hdr.rma_flag, oe_line.job_price_hdr_uid, oe_line.job_price_bin_uid, oe_hdr.order_type, CASE WHEN oe_hdr_class.class_description IS NULL 
                         THEN 'blank' ELSE oe_hdr_class.class_description END AS oe_hdr_class1_desc, CASE WHEN oe_hdr_class2.class_description IS NULL THEN 'blank' ELSE oe_hdr_class2.class_description END AS oe_hdr_class2_desc, 
                         CASE WHEN oe_hdr_class3.class_description IS NULL THEN 'blank' ELSE oe_hdr_class3.class_description END AS oe_hdr_class3_desc, CASE WHEN oe_hdr_class4.class_description IS NULL 
                         THEN 'blank' ELSE oe_hdr_class4.class_description END AS oe_hdr_class4_desc, CASE WHEN oe_hdr_class5.class_description IS NULL THEN 'blank' ELSE oe_hdr_class5.class_description END AS oe_hdr_class5_desc, 
                         COALESCE (oe_line.qty_ordered, 0) AS qty_ordered, oe_line.source_loc_id, oe_line.manual_price_overide, oe_line.required_date, inv_mast.extended_desc, inv_mast.item_desc, CASE WHEN class.class_description IS NULL 
                         THEN 'blank' ELSE class.class_description END AS Class1Desc, CASE WHEN class2.class_description IS NULL THEN 'blank' ELSE class2.class_description END AS Class2Desc, CASE WHEN class3.class_description IS NULL
                          THEN 'blank' ELSE class3.class_description END AS Class3DEsc, CASE WHEN class4.class_description IS NULL THEN 'blank' ELSE class4.class_description END AS Class4Desc, 
                         CASE WHEN class5.class_description IS NULL THEN 'blank' ELSE class5.class_description END AS Class5DEsc, CASE WHEN inv_mast_class1.class_description IS NULL 
                         THEN 'blank' ELSE inv_mast_class1.class_description END AS IMClass1, CASE WHEN inv_mast_class2.class_description IS NULL THEN 'blank' ELSE inv_mast_class2.class_description END AS IMClass2, 
                         CASE WHEN inv_mast_class3.class_description IS NULL THEN 'blank' ELSE inv_mast_class3.class_description END AS IMClass3, CASE WHEN inv_mast_class4.class_description IS NULL 
                         THEN 'blank' ELSE inv_mast_class4.class_description END AS IMClass4, CASE WHEN inv_mast_class5.class_description IS NULL THEN 'blank' ELSE inv_mast_class5.class_description END AS IMClass5, 
                         COALESCE (inv_loc.purchase_discount_group, inv_loc2.purchase_discount_group) AS purchase_discount_group, COALESCE (inv_loc.stockable, inv_loc2.stockable) AS stockable, COALESCE (inv_loc.qty_in_transit, 
                         inv_loc2.qty_in_transit, 0) AS qty_in_transit, COALESCE (inv_loc.tax_group_id, inv_loc2.tax_group_id) AS tax_group_id, CAST(COALESCE (inv_loc.price1, inv_loc2.price1) AS decimal(19, 4)) AS LocationPrice1, 
                         CAST(COALESCE (inv_loc.price2, inv_loc2.price2) AS decimal(19, 4)) AS LocationPrice2, CAST(COALESCE (inv_loc.price3, inv_loc2.price3) AS decimal(19, 4)) AS LocationPrice3, CAST(COALESCE (inv_loc.price4, inv_loc2.price4) 
                         AS decimal(19, 4)) AS LocationPrice4, CAST(COALESCE (inv_loc.price5, inv_loc2.price5) AS decimal(19, 4)) AS LocationPrice5, CAST(COALESCE (inv_loc.price6, inv_loc2.price6) AS decimal(19, 4)) AS LocationPrice6, 
                         CAST(COALESCE (inv_loc.price7, inv_loc2.price7) AS decimal(19, 4)) AS LocationPrice7, CAST(COALESCE (inv_loc.price8, inv_loc2.price8) AS decimal(19, 4)) AS LocationPrice8, CAST(COALESCE (inv_loc.price9, inv_loc2.price9) 
                         AS decimal(19, 4)) AS LocationPrice9, CAST(COALESCE (inv_loc.price10, inv_loc2.price9) AS decimal(19, 4)) AS LocationPrice10, COALESCE (inv_loc.last_rec_po, inv_loc2.last_rec_po) AS last_rec_po, 
                         COALESCE (inv_loc.purchase_class, inv_loc2.purchase_class) AS Purchase_Class, isup.upc_code, isup.supplier_part_no, isup.manufacturing_class_id, isup.division_id, branch.branch_description, company.company_name, 
                         COALESCE (product_group.product_group_desc, 'Blank') AS product_group_desc, supplier.supplier_name, invoice_class.invoice_class_desc AS InvoiceClassdesc, location.location_name, 
                         document_types.document_type_description AS Invoice_typedesc, code_p21.code_description AS InvoiceLineTypeDesc, COALESCE (discount_group.discount_group_description, discount_group2.discount_group_description) 
                         AS discount_group_description, COALESCE (tax_group_hdr.tax_group_description, tax_group_hdr2.tax_group_description) AS tax_group_description, vendor_supplier.vendor_id, vendor.vendor_name, 
                         ISNULL(Corp_ID.address_name, customer.customer_name) AS CorpName, invoice_hdr_salesrep.salesrep_id AS SalesRepIDOrder, ship_to_salesrep.salesrep_id AS SalesRepIDShip, 
                         shptax_group_hdr.tax_group_description AS shiptoTaxGrpDesc, ship_to.tax_group_id AS shiptotaxid, p.beginning_date AS Period_Date, CASE WHEN oe_hdr.source_code_no IN (1877, 1916, 1918) 
                         THEN 'Y' ELSE 'N' END AS Manufacturer_Rep_Order, CASE WHEN oe_line.disposition IS NULL OR
                         ltrim(oe_line.disposition) = '' THEN COALESCE (oe_pick_ticket.direct_shipment, 'N') ELSE CASE oe_line.disposition WHEN 'D' THEN 'Y' ELSE 'N' END END AS Direct_Flag, CASE WHEN oe_line.disposition IS NULL OR
                         ltrim(oe_line.disposition) = '' THEN CASE WHEN oe_pick_ticket.direct_shipment = 'y' THEN 'D' ELSE 'W' END ELSE oe_line.disposition END AS disposition, DATEDIFF(dd, COALESCE (oe_hdr.requested_date, 
                         invoice_hdr.ship_date), invoice_hdr.ship_date) AS Days_to_ship, DATEDIFF(dd, oe_hdr.requested_date, invoice_hdr.ship_date) AS Days_to_ship2, CASE WHEN datediff(dd, COALESCE (oe_hdr.requested_date, 
                         invoice_hdr.ship_date), invoice_hdr.ship_date) > 0 THEN datediff(dd, COALESCE (oe_hdr.requested_date, invoice_hdr.ship_date), invoice_hdr.ship_date) ELSE 0 END AS OnTimeDaysLate, 1.00 AS TotalLines, 
                         CASE WHEN datediff(dd, COALESCE (oe_hdr.requested_date, invoice_hdr.ship_date), invoice_hdr.ship_date) < 0 THEN datediff(dd, COALESCE (oe_hdr.requested_date, invoice_hdr.ship_date), invoice_hdr.ship_date) 
                         ELSE 0 END AS Days_Early, CASE WHEN CAST(datediff(dd, COALESCE (oe_hdr.requested_date, invoice_hdr.ship_date), invoice_hdr.ship_date) AS int) = 0 THEN 'OnTime' WHEN CAST(datediff(dd, 
                         COALESCE (oe_hdr.requested_date, invoice_hdr.ship_date), invoice_hdr.ship_date) AS int) > 0 THEN 'Late' WHEN CAST(datediff(dd, COALESCE (oe_hdr.requested_date, invoice_hdr.ship_date), invoice_hdr.ship_date) AS int) 
                         < 0 THEN 'Early' ELSE 'NA' END AS OnTimeDesc, DATEPART(week, oe_line.required_date) AS RequiredWeekNo, CAST(CASE WHEN (datediff(dd, CONVERT(datetime, CONVERT(char(10), required_date, 120), 120), 
                         CONVERT(datetime, CONVERT(char(10), invoice_hdr.ship_date, 120), 120)) > 0 OR
                         ((invoice_adjustment_type = 'I' AND invoice_hdr.invoice_class = 'Z') OR
                         (invoice_adjustment_type = 'A'))) THEN 0.00 ELSE 1.00 END AS real) AS CountOnTime, CASE WHEN ((invoice_adjustment_type = 'I' AND invoice_hdr.invoice_class = 'Z') OR
                         (invoice_adjustment_type = 'A')) THEN 0.00 WHEN invoice_line_type IN (982, 981) THEN 0 WHEN isnull(rma_flag, 'n') = 'Y' THEN 0 WHEN invoice_hdr.order_no IS NULL THEN 0 ELSE 1.00 END AS Linecount, 
                         CASE WHEN invoice_line.invoice_line_uid IN
                             (SELECT        invoice_line_uid_parent
                               FROM            p21.dbo.invoice_line) THEN 0.00 WHEN invoice_line_type IN (929, 928, 930) THEN 0.00 ELSE 1.00 END AS lines_picked, 1 AS line_count, oe_pick_ticket.tracking_no, oe_hdr.source_code_no, 
                         SourceCode.code_description AS source_code, oe_hdr.source_id, CASE WHEN contactsShip.id IN
                             (SELECT DISTINCT sales_manager_id 
                               FROM            p21.dbo.contacts
                               WHERE        salesrep = 'y' AND delete_flag = 'n' AND sales_manager_id IS NOT NULL) 
                         THEN contactsShip.last_name + ', ' + contactsShip.first_name ELSE manager.last_name + ', ' + manager.first_name END AS Sales_Manager, oe_pick_ticket.pick_ticket_no, custAddress.mail_address1, 
                         custAddress.mail_address2, custAddress.mail_city, custAddress.mail_state, custAddress.mail_postal_code, custAddress.mail_country, custAddress.phys_address1, custAddress.phys_address2, custAddress.phys_city, 
                         custAddress.phys_state, custAddress.phys_postal_code, custAddress.phys_country, custAddress.central_phone_number, custAddress.central_fax_number, customer.trading_partner_name, 
                         ISNULL(CAST(ols.release_no AS varchar(20)), '') AS release_no, ISNULL(ols.printed, 'Blank') AS release_printed, CONVERT(DATETIME, CONVERT(CHAR(10), ols.release_date, 120), 120) AS release_date, CONVERT(DATETIME, 
                         CONVERT(CHAR(10), ols.pick_date, 120), 120) AS release_pick_date, CONVERT(DATETIME, CONVERT(CHAR(10), ols.expedite_date, 120), 120) AS release_expedite_date, ols.release_qty, ols.release_status_flag, 
                         ISNULL(oept.release_no, 0) AS pt_release_no, pp.description AS price_page, ppc.code_description AS calculation_method, pp.calculation_value1 AS calculation_value, inv_mast.generic_item_desc, iud.legacy_item_id, 
                         iud.legacy_item_description
FROM            dbo.p21_view_invoice_line AS invoice_line LEFT OUTER JOIN
                         dbo.oe_pick_ticket AS oe_pick_ticket ON oe_pick_ticket.invoice_id_when_shipped = invoice_line.invoice_no LEFT OUTER JOIN
                         dbo.oe_pick_ticket_detail AS oept ON oept.pick_ticket_no = oe_pick_ticket.pick_ticket_no AND oept.invoice_line_uid = invoice_line.invoice_line_uid LEFT OUTER JOIN
                         dbo.invoice_hdr AS invoice_hdr ON invoice_hdr.invoice_no = invoice_line.invoice_no LEFT OUTER JOIN
                         dbo.invoice_hdr_salesrep AS invoice_hdr_salesrep ON invoice_hdr_salesrep.invoice_number = invoice_hdr.invoice_no AND invoice_hdr_salesrep.primary_salesrep = 'y' LEFT OUTER JOIN
                         dbo.ship_to_salesrep AS ship_to_salesrep ON ship_to_salesrep.ship_to_id = invoice_hdr.ship_to_id AND ship_to_salesrep.company_id = invoice_hdr.company_no AND ship_to_salesrep.primary_salesrep = 'y' AND 
                         ship_to_salesrep.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.contacts AS contactsShip ON ship_to_salesrep.salesrep_id = contactsShip.id LEFT OUTER JOIN
                         dbo.contacts AS manager WITH (nolock) ON manager.id = contactsShip.sales_manager_id LEFT OUTER JOIN
                         dbo.contacts AS contacts ON contacts.id = invoice_hdr_salesrep.salesrep_id LEFT OUTER JOIN
                         dbo.oe_line AS oe_line ON oe_line.order_no = invoice_line.order_no AND oe_line.line_no = invoice_line.oe_line_number LEFT OUTER JOIN
                         dbo.oe_line_schedule AS ols ON ols.order_no = invoice_line.order_no AND ols.line_no = invoice_line.oe_line_number AND ols.release_no = oept.release_no LEFT OUTER JOIN
                         dbo.inv_loc AS inv_loc ON inv_loc.inv_mast_uid = oe_line.inv_mast_uid AND inv_loc.location_id = oe_line.source_loc_id LEFT OUTER JOIN
                         dbo.supplier AS supplier ON invoice_line.supplier_id = supplier.supplier_id LEFT OUTER JOIN
                         dbo.vendor_supplier AS vendor_supplier ON inv_loc.primary_supplier_id = vendor_supplier.supplier_id AND invoice_hdr.company_no = vendor_supplier.company_id AND vendor_supplier.delete_flag = 'n' AND 
                         vendor_supplier.primary_vendor = 'y' LEFT OUTER JOIN
                         dbo.vendor AS vendor ON vendor.vendor_id = vendor_supplier.vendor_id AND invoice_hdr.company_no = vendor.company_id LEFT OUTER JOIN
                         dbo.inventory_supplier AS isup ON isup.inv_mast_uid = inv_loc.inv_mast_uid AND isup.supplier_id = inv_loc.primary_supplier_id LEFT OUTER JOIN
                         dbo.customer AS customer ON invoice_hdr.customer_id = customer.customer_id AND invoice_hdr.company_no = customer.company_id LEFT OUTER JOIN
                         dbo.code_p21 AS code_p21 ON code_code_no = invoice_line.invoice_line_type LEFT OUTER JOIN
                         dbo.discount_group AS discount_group ON discount_group.discount_group_id = inv_loc.purchase_discount_group LEFT OUTER JOIN
                         dbo.tax_group_hdr AS tax_group_hdr ON inv_loc.tax_group_id = tax_group_hdr.tax_group_id AND inv_loc.company_id = tax_group_hdr.company_id LEFT OUTER JOIN
                         dbo.product_group AS product_group ON COALESCE (invoice_line.product_group_id, oe_line.product_group_id, inv_loc.product_group_id, 'Blank') = product_group.product_group_id AND 
                         invoice_line.company_id = product_group.company_id LEFT OUTER JOIN
                         dbo.inv_mast AS inv_mast ON invoice_line.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         dbo.inv_mast_ud AS iud WITH (nolock) ON iud.inv_mast_uid = inv_mast.inv_mast_uid LEFT OUTER JOIN
                         dbo.document_types AS document_types ON document_types.document_type_id = invoice_hdr.invoice_type AND document_types.document_id = 'I' LEFT OUTER JOIN
                         dbo.invoice_class AS invoice_class ON invoice_hdr.invoice_class = invoice_class.invoice_class LEFT OUTER JOIN
                         dbo.location AS location ON invoice_hdr.sales_location_id = location.location_id AND invoice_hdr.company_no = location.company_id AND location.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.contacts AS contacts2 ON customer.salesrep_id = contacts2.id LEFT OUTER JOIN
                         dbo.branch AS branch ON invoice_hdr.branch_id = branch.branch_id AND invoice_hdr.company_no = branch.company_id LEFT OUTER JOIN
                         dbo.oe_hdr AS oe_hdr ON invoice_hdr.order_no = oe_hdr.order_no LEFT OUTER JOIN
                         dbo.company AS company ON invoice_hdr.company_no = company.company_id LEFT OUTER JOIN
                         dbo.class AS class ON customer.class_1id = class.class_id AND class.class_number = 1 AND class.class_type = 'cs' AND class.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS class2 ON customer.class_2id = class2.class_id AND class2.class_number = 2 AND class2.class_type = 'cs' AND class2.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS class3 ON customer.class_3id = class3.class_id AND class3.class_number = 3 AND class3.class_type = 'cs' AND class3.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS class4 ON customer.class_4id = class4.class_id AND class4.class_number = 4 AND class4.class_type = 'cs' AND class4.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS class5 ON customer.class_5id = class5.class_id AND class5.class_number = 5 AND class5.class_type = 'cs' AND class5.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.product_group AS product_group2 ON oe_line.product_group_id = product_group2.product_group_id AND oe_line.company_no = product_group2.company_id LEFT OUTER JOIN
                         dbo.inv_loc AS inv_loc2 ON invoice_hdr.sales_location_id = inv_loc2.location_id AND invoice_line.inv_mast_uid = inv_loc2.inv_mast_uid LEFT OUTER JOIN
                         dbo.tax_group_hdr AS tax_group_hdr2 ON inv_loc2.tax_group_id = tax_group_hdr2.tax_group_id AND inv_loc2.company_id = tax_group_hdr2.company_id LEFT OUTER JOIN
                         dbo.discount_group AS discount_group2 ON inv_loc2.purchase_discount_group = discount_group2.discount_group_id LEFT OUTER JOIN
                         dbo.corp_id AS Corp_ID ON Corp_ID.company_id = invoice_hdr.company_no AND Corp_ID.address_id = invoice_hdr.corp_address_id AND Corp_ID.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS oe_hdr_class WITH (nolock) ON oe_hdr.class_1id = oe_hdr_class.class_id AND oe_hdr_class.class_number = 1 AND oe_hdr_class.class_type = 'oe' AND oe_hdr_class.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS oe_hdr_class2 WITH (nolock) ON oe_hdr.class_2id = oe_hdr_class2.class_id AND oe_hdr_class2.class_number = 2 AND oe_hdr_class2.class_type = 'oe' AND oe_hdr_class2.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS oe_hdr_class3 WITH (nolock) ON oe_hdr.class_3id = oe_hdr_class3.class_id AND oe_hdr_class3.class_number = 3 AND oe_hdr_class3.class_type = 'oe' AND oe_hdr_class3.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS oe_hdr_class4 WITH (nolock) ON oe_hdr.class_4id = oe_hdr_class4.class_id AND oe_hdr_class4.class_number = 4 AND oe_hdr_class4.class_type = 'oe' AND oe_hdr_class4.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS oe_hdr_class5 WITH (nolock) ON oe_hdr.class_5id = oe_hdr_class5.class_id AND oe_hdr_class5.class_number = 5 AND oe_hdr_class5.class_type = 'oe' AND oe_hdr_class5.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.ship_to AS ship_to WITH (nolock) ON ship_to.ship_to_id = invoice_hdr.ship_to_id AND ship_to.company_id = invoice_hdr.company_no AND ship_to.delete_flag <> 'y' LEFT OUTER JOIN
                         dbo.tax_group_hdr AS shptax_group_hdr WITH (nolock) ON ship_to.tax_group_id = shptax_group_hdr.tax_group_id AND ship_to.company_id = shptax_group_hdr.company_id AND 
                         shptax_group_hdr.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS inv_mast_class1 WITH (nolock) ON inv_mast.class_id1 = inv_mast_class1.class_id AND inv_mast_class1.class_number = 1 AND inv_mast_class1.class_type = 'iv' AND 
                         inv_mast_class1.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS inv_mast_class2 WITH (nolock) ON inv_mast.class_id2 = inv_mast_class2.class_id AND inv_mast_class2.class_number = 2 AND inv_mast_class2.class_type = 'iv' AND 
                         inv_mast_class2.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS inv_mast_class3 WITH (nolock) ON inv_mast.class_id3 = inv_mast_class3.class_id AND inv_mast_class3.class_number = 3 AND inv_mast_class3.class_type = 'iv' AND 
                         inv_mast_class3.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS inv_mast_class4 WITH (nolock) ON inv_mast.class_id4 = inv_mast_class4.class_id AND inv_mast_class4.class_number = 4 AND inv_mast_class4.class_type = 'iv' AND 
                         inv_mast_class4.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.class AS inv_mast_class5 WITH (nolock) ON inv_mast.class_id5 = inv_mast_class5.class_id AND inv_mast_class5.class_number = 5 AND inv_mast_class5.class_type = 'iv' AND 
                         inv_mast_class5.delete_flag = 'n' LEFT OUTER JOIN
                         dbo.item_uom AS item_uom WITH (nolock) ON item_uom.inv_mast_uid = invoice_line.inv_mast_uid AND item_uom.unit_of_measure = invoice_line.unit_of_measure LEFT OUTER JOIN
                         dbo.code_p21 AS SourceCode ON oe_hdr.source_code_no = SourceCode.code_no AND SourceCode.row_status_flag = 'A' LEFT OUTER JOIN
                         dbo.periods AS p ON p.period = invoice_hdr.period AND p.year_for_period = invoice_hdr.year_for_period AND p.company_no = invoice_hdr.company_no LEFT OUTER JOIN
                         dbo.address AS custAddress WITH (nolock) ON customer.customer_id = custAddress.id LEFT OUTER JOIN
                         dbo.price_page AS pp WITH (nolock) ON pp.price_page_uid = oe_line.price_page_uid LEFT OUTER JOIN
                         dbo.code_p21 AS ppc WITH (nolock) ON ppc.code_no = pp.calculation_method_cd LEFT OUTER JOIN
                         dbo.manufacturing_class AS mc WITH (nolock) ON mc.manufacturing_class_id = isup.manufacturing_class_id LEFT OUTER JOIN
                         dbo.supplier_ud AS supplier_ud WITH (nolock) ON supplier_ud.supplier_id = inv_loc.primary_supplier_id
WHERE        (invoice_hdr.approved = 'Y') AND (invoice_hdr.invoice_class <> 'FINANCE') AND (invoice_hdr.invoice_adjustment_type NOT IN ('B', 'T', 'X', 'R', 'W', 'A', 'P', 'Z', 'Y')) AND (invoice_hdr.consolidated <> 'C') AND 
                         (invoice_line.invoice_line_type NOT IN (3)) AND (invoice_hdr.original_document_type <> 'T') AND (invoice_line.item_id NOT IN ('DOWNPAYMENT', 'PREPAYMENT')) AND (invoice_line.qty_shipped > 0.0000 and inv_mast.inv_mast_uid = 32435 and inv_loc.location_id = 300 OR
                         invoice_line.qty_shipped < 0.0000) AND (invoice_line.item_id <> 'ADVANCE BILL AMOUNT') AND (COALESCE (oe_line.lot_bill, 'N') = 'N') OR
                         (invoice_hdr.approved = 'Y') AND (invoice_hdr.invoice_class <> 'FINANCE') AND (invoice_hdr.invoice_adjustment_type NOT IN ('B', 'T', 'X', 'R', 'W', 'A', 'P', 'Z', 'Y')) AND (invoice_hdr.consolidated <> 'C') AND 
                         (invoice_line.invoice_line_type NOT IN (3)) AND (invoice_hdr.original_document_type <> 'T') AND (invoice_line.item_id NOT IN ('DOWNPAYMENT', 'PREPAYMENT')) AND (invoice_line.qty_shipped > 0.0000 and inv_mast.inv_mast_uid = 32435 and inv_loc.location_id = 300 OR
                         invoice_line.qty_shipped < 0.0000) AND (invoice_line.item_id <> 'ADVANCE BILL AMOUNT') AND (oe_line.lot_bill = 'Y') AND (invoice_line.invoice_line_uid_parent = 0) AND (invoice_line.invoice_line_type = 4) and inv_mast.inv_mast_uid = 32435 and inv_loc.location_id = 300
order by SIMG