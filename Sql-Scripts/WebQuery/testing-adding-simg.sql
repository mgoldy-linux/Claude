select top 8000 invoice_line.inv_mast_uid, *
from  dbo.p21_view_invoice_line AS invoice_line LEFT OUTER JOIN
dbo.oe_pick_ticket AS oe_pick_ticket ON oe_pick_ticket.invoice_id_when_shipped = invoice_line.invoice_no 
LEFT OUTER JOIN
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
dbo.code_p21 AS code_p21 ON code_p21.code_no = invoice_line.invoice_line_type LEFT OUTER JOIN
dbo.discount_group AS discount_group ON discount_group.discount_group_id = inv_loc.purchase_discount_group LEFT OUTER JOIN
dbo.tax_group_hdr AS tax_group_hdr ON inv_loc.tax_group_id = tax_group_hdr.tax_group_id AND inv_loc.company_id = tax_group_hdr.company_id LEFT OUTER JOIN
dbo.product_group AS product_group ON COALESCE (invoice_line.product_group_id, oe_line.product_group_id, inv_loc.product_group_id, 'Blank') = product_group.product_group_id AND invoice_line.company_id = product_group.company_id LEFT OUTER JOIN
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
where invoice_line.inv_mast_uid = 32435