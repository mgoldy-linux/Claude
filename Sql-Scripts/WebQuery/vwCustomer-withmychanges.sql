-- add territory description
SELECT        customer.legacy_id AS customer_legacy_id, ship_to.ship_to_id, ShipToAddress.name AS ship_to_name, ship_to.default_carrier_id, customer.trading_partner_name, customer.interchg_receiver_id, customer.customer_id, 
                         customer.company_id, company.company_name, customer.customer_name, customer.terms_id, customer.salesrep_id, customer.last_maintained_by, customer.class_1id, customer.last_check_number, 
                         customer.last_check_amount, customer.sic_code, customer.pricing_method_cd, customer.source_price_cd, customer.multiplier, customer.source_type_cd, customer.credit_limit, customer.credit_limit_used, 
                         customer.delete_flag, customer.accept_partial_orders, customer.acceptable_wait_time, customer.credit_limit_per_order, customer.bill_to_contact_id, customer.minimum_order_dollar_amount, 
                         customer.federal_exemption_number, customer.other_exemption_number, customer.default_disposition, customer.fc_percentage, customer.fc_grace_days, customer.minimum_finance_charge, customer.fc_cycle, 
                         CONVERT(datetime, CONVERT(char(10), customer.last_fc_date, 120), 120) AS last_fc_date, customer.highest_credit_limit_used, customer.state_excise_tax_exemption_no, customer.credit_status, 
                         credit_status.credit_status_desc, customer.use_consolidated_invoicing, customer.po_no_required, customer.default_branch_id, CONVERT(datetime, CONVERT(char(10), customer.last_check_date, 120), 120) AS last_check_date, 
                         CONVERT(datetime, CONVERT(char(10), customer.date_acct_opened, 120), 120) AS date_acct_opened, CONVERT(datetime, CONVERT(char(10), customer.date_created, 120), 120) AS date_created, CONVERT(datetime, 
                         CONVERT(char(10), customer.date_last_modified, 120), 120) AS date_last_modified, terms.terms_desc, terms.discount_pct, terms.discount_days, terms.net_days, terms.day_of_month, terms.months, 
                         terms.terms_day_of_month, terms.terms_months, terms.downpayment_pct, contacts.last_name + ', ' + contacts.first_name AS salesrep_name, CASE WHEN class.class_description IS NULL 
                         THEN 'blank' ELSE class.class_description END AS Class1Desc, customer.class_2id, CASE WHEN class2.class_description IS NULL THEN 'blank' ELSE class2.class_description END AS Class2Desc, customer.class_3id, 
                         CASE WHEN class3.class_description IS NULL THEN 'blank' ELSE class3.class_description END AS Class3Desc, customer.class_4id, CASE WHEN class4.class_description IS NULL 
                         THEN 'blank' ELSE class4.class_description END AS Class4Desc, customer.class_5id, CASE WHEN class5.class_description IS NULL THEN 'blank' ELSE class5.class_description END AS Class5Desc, 
                         CASE WHEN sh_class1.class_description IS NULL THEN 'blank' ELSE sh_class1.class_description END AS Ship_Class_1, CASE WHEN sh_class2.class_description IS NULL 
                         THEN 'blank' ELSE sh_class2.class_description END AS Ship_Class_2, CASE WHEN sh_class3.class_description IS NULL THEN 'blank' ELSE sh_class3.class_description END AS Ship_Class_3, 
                         CASE WHEN sh_class4.class_description IS NULL THEN 'blank' ELSE sh_class4.class_description END AS Ship_Class_4, CASE WHEN sh_class5.class_description IS NULL 
                         THEN 'blank' ELSE sh_class5.class_description END AS Ship_Class_5,
                             (SELECT        sic_description
                               FROM            Play2.dbo.sic AS sic
                               WHERE        (customer.sic_code = sic_code)) AS sic_description, freight_code.freight_cd, freight_code.freight_desc, carrierAddress.name AS default_carrier_name, COALESCE
                             ((SELECT        code_description
                                 FROM            Play2.dbo.code_p21 AS code_p21
                                 WHERE        (customer.pricing_method_cd = code_no)), 'Undefined') AS pricing_method_desc, COALESCE
                             ((SELECT        code_description
                                 FROM            Play2.dbo.code_p21 AS code_p21_2
                                 WHERE        (customer.source_price_cd = code_no)), 'Undefined') AS source_price_desc, COALESCE
                             ((SELECT        code_description
                                 FROM            Play2.dbo.code_p21 AS code_p21_1
                                 WHERE        (customer.source_type_cd = code_no)), 'Undefined') AS source_type_desc, COALESCE (vwR12Customer.R12QtyShip, 0) AS R12QtyShip, COALESCE (vwR12Customer.R12Sales, 0) AS R12Sales, 
                         COALESCE (vwR12Customer.R12Cost, 0) AS R12Cost, COALESCE (vwR12Customer.R12GM, 0) AS R12Gm, COALESCE (vwR12Customer.R12MonthsSold, 0) AS R12MonthsSold, COALESCE (vwR12Customer.R12Lines, 0) 
                         AS R12Lines, COALESCE (vwR12Customer.R12Sales / 365, 0) AS AvgDailySales, COALESCE (AROpenInvoices.TotAmount, 0) AS TotAmount, COALESCE (AROpenInvoices.Paid, 0) AS Paid, COALESCE (AROpenInvoices.TermsAmt, 
                         0) AS TermsAmt, COALESCE (AROpenInvoices.MemoAmt, 0) AS MemoAmt, COALESCE (AROpenInvoices.BalanceDue, 0) AS BalanceDue, COALESCE (AROpenInvoices.BalanceDueInvDateAge1, 0) AS BalanceDueInvDateAge1, 
                         COALESCE (AROpenInvoices.BalanceDueInvDateAge2, 0) AS BalanceDueInvDateAge2, COALESCE (AROpenInvoices.BalanceDueInvDateAge3, 0) AS BalanceDueInvDateAge3, 
                         COALESCE (AROpenInvoices.BalanceDueInvDateAge4, 0) AS BalanceDueInvDateAge4, COALESCE (AROpenInvoices.BalanceDueInvDateAge5, 0) AS BalanceDueInvDateAge5, 
                         COALESCE (AROpenInvoices.BalanceDueNetDueDateAge0, 0) AS BalanceDueNetDueDateAge0, COALESCE (AROpenInvoices.BalanceDueNetDueDateAge1, 0) AS BalanceDueNetDueDateAge1, 
                         COALESCE (AROpenInvoices.BalanceDueNetDueDateAge2, 0) AS BalanceDueNetDueDateAge2, COALESCE (AROpenInvoices.BalanceDueNetDueDateAge3, 0) AS BalanceDueNetDueDateAge3, 
                         COALESCE (AROpenInvoices.BalanceDueNetDueDateAge4, 0) AS BalanceDueNetDueDateAge4, COALESCE (AROpenInvoices.BalanceDueNetDueDateAge5, 0) AS BalanceDueNetDueDateAge5, 
                         ISNULL(AROpenInvoices.BalanceDueInvDateAge1 + AROpenInvoices.BalanceDueInvDateAge2 + AROpenInvoices.BalanceDueInvDateAge3 + AROpenInvoices.BalanceDueInvDateAge4 + AROpenInvoices.BalanceDueInvDateAge5,
                          0) AS BalanceDueInvDatePastDue, COALESCE (ARClosedInvoices.AvgDaysToPay, 0) AS AvgDaysToPay, custAddress.mail_address1, custAddress.mail_address2, custAddress.mail_city, custAddress.mail_state, 
                         custAddress.mail_postal_code, custAddress.mail_country, custAddress.phys_address1, custAddress.phys_address2, custAddress.phys_city, custAddress.phys_state, custAddress.phys_postal_code, 
                         custAddress.phys_country, custAddress.central_phone_number, custAddress.central_fax_number, ShipToAddress.mail_address1 AS ship2__mail_add1, ShipToAddress.mail_address2 AS ship2_mail_add2, 
                         ShipToAddress.mail_city AS ship2_mail_city, ShipToAddress.mail_state AS ship2_mail_state, ShipToAddress.mail_postal_code AS ship2_mail_zip, ShipToAddress.mail_country AS ship2_mail_country, 
                         ShipToAddress.phys_address1 AS ship2_phys_add1, ShipToAddress.phys_address2 AS ship2_phys_add2, ShipToAddress.phys_city AS ship2_phys_city, ShipToAddress.phys_state AS ship2_phys_state, 
                         ShipToAddress.phys_postal_code AS ship2_phys_zip, ShipToAddress.phys_country AS ship2_phys_country, ShipToAddress.central_phone_number AS ship2_central_phone, ShipToAddress.central_fax_number AS ship2_fax, 
                         custContacts.last_name + ', ' + custContacts.first_name AS BillToContact, custContacts.title AS BillToTitle, custContacts.direct_phone AS BillToPhone, custContacts.phone_ext AS BillToPhoneExt, 
                         custContacts.cellular AS BillToCellular, custContacts.email_address AS BillToEmailAddress, ship_to_salesrep.salesrep_id AS salesrep_id_ship_to, 
                         shiptoContacts.last_name + ', ' + shiptoContacts.first_name AS salesrep_name_ship_to, CASE WHEN shiptoContacts.id IN
                             (SELECT DISTINCT sales_manager_id
                               FROM            p21.dbo.contacts
                               WHERE        salesrep = 'y' AND delete_flag = 'n' AND sales_manager_id IS NOT NULL) 
                         THEN shiptoContacts.last_name + ', ' + shiptoContacts.first_name ELSE manager.last_name + ', ' + manager.first_name END AS Sales_Manager,t.territory_desc
FROM            Play2.dbo.ship_to AS ship_to WITH (nolock) LEFT OUTER JOIN
                         Play2.dbo.customer AS customer ON ship_to.company_id = customer.company_id AND ship_to.customer_id = customer.customer_id LEFT OUTER JOIN
                             (SELECT        company_no, ship_to_id, SUM(qty_shipped) AS R12QtyShip, SUM(Extended_Price) AS R12Sales, SUM(Cogs_Amount) AS R12Cost, SUM(Extended_Price) - SUM(Cogs_Amount) AS R12GM, 
                                                         COUNT(DISTINCT MONTH(InvoiceDate)) AS R12MonthsSold, COUNT(invoice_line_uid) AS R12Lines
                               FROM            dbo.vwSalesAnalysis
                               WHERE        (InvoiceDate >= CAST(CAST(DATEPART(mm, GETDATE()) AS varchar(2)) + '/1/' + CAST(DATEPART(YY, DATEADD(yy, - 1, GETDATE())) AS varchar(4)) AS datetime)) AND (InvoiceDate < CAST(CAST(DATEPART(mm, 
                                                         GETDATE()) AS varchar(2)) + '/1/' + CAST(DATEPART(YY, GETDATE()) AS varchar(4)) AS datetime))
                               GROUP BY company_no, ship_to_id) AS vwR12Customer ON ship_to.company_id = vwR12Customer.company_no AND ship_to.ship_to_id = vwR12Customer.ship_to_id LEFT OUTER JOIN
                             (SELECT        Company, ShipToId, SUM(TotAmount) AS TotAmount, SUM(Paid) AS Paid, SUM(TermsAmt) AS TermsAmt, SUM(MemoAmt) AS MemoAmt, SUM(BalanceDue) AS BalanceDue, 
                                                         SUM(CASE WHEN InvAge_no = 1 THEN BalanceDue ELSE 0 END) AS BalanceDueInvDateAge1, SUM(CASE WHEN InvAge_no = 2 THEN BalanceDue ELSE 0 END) AS BalanceDueInvDateAge2, 
                                                         SUM(CASE WHEN InvAge_no = 3 THEN BalanceDue ELSE 0 END) AS BalanceDueInvDateAge3, SUM(CASE WHEN InvAge_no = 4 THEN BalanceDue ELSE 0 END) AS BalanceDueInvDateAge4, 
                                                         SUM(CASE WHEN InvAge_no = 5 THEN BalanceDue ELSE 0 END) AS BalanceDueInvDateAge5, SUM(CASE WHEN Age_no = 0 THEN BalanceDue ELSE 0 END) AS BalanceDueNetDueDateAge0, 
                                                         SUM(CASE WHEN Age_no = 1 THEN BalanceDue ELSE 0 END) AS BalanceDueNetDueDateAge1, SUM(CASE WHEN Age_no = 2 THEN BalanceDue ELSE 0 END) AS BalanceDueNetDueDateAge2, 
                                                         SUM(CASE WHEN Age_no = 3 THEN BalanceDue ELSE 0 END) AS BalanceDueNetDueDateAge3, SUM(CASE WHEN Age_no = 4 THEN BalanceDue ELSE 0 END) AS BalanceDueNetDueDateAge4, 
                                                         SUM(CASE WHEN Age_no = 5 THEN BalanceDue ELSE 0 END) AS BalanceDueNetDueDateAge5
                               FROM            dbo.vwAROpenInvoices
                               GROUP BY Company, ShipToId) AS AROpenInvoices ON ship_to.company_id = AROpenInvoices.Company AND ship_to.ship_to_id = AROpenInvoices.ShipToId LEFT OUTER JOIN
                             (SELECT        company_no, ship_to_id, AVG(DATEDIFF(dd, invoice_date, date_paid)) AS AvgDaysToPay
                               FROM            Play2.dbo.invoice_hdr
                               WHERE        (paid_in_full_flag = 'Y')
                               GROUP BY company_no, ship_to_id) AS ARClosedInvoices ON ship_to.company_id = ARClosedInvoices.company_no AND ship_to.ship_to_id = ARClosedInvoices.ship_to_id LEFT OUTER JOIN
                         Play2.dbo.freight_code AS freight_code WITH (nolock) ON ship_to.freight_code_uid = freight_code.freight_code_uid LEFT OUTER JOIN
                         Play2.dbo.terms AS terms WITH (nolock) ON customer.terms_id = terms.terms_id LEFT OUTER JOIN
                         Play2.dbo.contacts AS contacts WITH (nolock) ON customer.salesrep_id = contacts.id LEFT OUTER JOIN
                         Play2.dbo.class AS class WITH (nolock) ON customer.class_1id = class.class_id AND class.class_number = 1 AND class.class_type = 'cs' AND class.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass2 WITH (nolock) ON customer.class_2id = CLass2.class_id AND CLass2.class_number = 2 AND CLass2.class_type = 'cs' AND CLass2.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass3 WITH (nolock) ON customer.class_3id = CLass3.class_id AND CLass3.class_number = 3 AND CLass3.class_type = 'cs' AND CLass3.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass4 WITH (nolock) ON customer.class_4id = CLass4.class_id AND CLass4.class_number = 4 AND CLass4.class_type = 'cs' AND CLass4.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS CLass5 WITH (nolock) ON customer.class_5id = CLass5.class_id AND CLass5.class_number = 5 AND CLass5.class_type = 'cs' AND CLass5.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.contacts AS custContacts WITH (nolock) ON customer.bill_to_contact_id = custContacts.id LEFT OUTER JOIN
                         Play2.dbo.address AS custAddress WITH (nolock) ON customer.customer_id = custAddress.id LEFT OUTER JOIN
                         Play2.dbo.company AS company WITH (nolock) ON customer.company_id = company.company_id LEFT OUTER JOIN
                         Play2.dbo.credit_status AS credit_status WITH (nolock) ON customer.credit_status = credit_status.credit_status_id LEFT OUTER JOIN
                         Play2.dbo.ship_to_salesrep AS ship_to_salesrep WITH (nolock) ON ship_to.company_id = ship_to_salesrep.company_id AND ship_to.ship_to_id = ship_to_salesrep.ship_to_id AND ship_to_salesrep.primary_salesrep = 'Y' AND
                          ship_to_salesrep.delete_flag = 'N' LEFT OUTER JOIN
                         Play2.dbo.contacts AS shiptoContacts WITH (nolock) ON ship_to_salesrep.salesrep_id = shiptoContacts.id LEFT OUTER JOIN
                         P21.dbo.contacts AS manager WITH (nolock) ON manager.id = shiptoContacts.sales_manager_id LEFT OUTER JOIN
                         Play2.dbo.address AS ShipToAddress WITH (nolock) ON ship_to.ship_to_id = ShipToAddress.id LEFT OUTER JOIN
                         Play2.dbo.class AS sh_class1 WITH (nolock) ON ship_to.class1_id = sh_class1.class_id AND sh_class1.class_number = 1 AND sh_class1.class_type = 'cs' AND sh_class1.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS sh_class2 WITH (nolock) ON ship_to.class2_id = sh_class2.class_id AND sh_class2.class_number = 2 AND sh_class2.class_type = 'cs' AND sh_class2.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS sh_class3 WITH (nolock) ON ship_to.class3_id = sh_class3.class_id AND sh_class3.class_number = 3 AND sh_class3.class_type = 'cs' AND sh_class3.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS sh_class4 WITH (nolock) ON ship_to.class4_id = sh_class4.class_id AND sh_class4.class_number = 4 AND sh_class4.class_type = 'cs' AND sh_class4.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS sh_class5 WITH (nolock) ON ship_to.class5_id = sh_class5.class_id AND sh_class5.class_number = 5 AND sh_class5.class_type = 'cs' AND sh_class5.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.address AS carrierAddress WITH (nolock) ON ship_to.default_carrier_id = carrierAddress.id Left join
						 Play2.dbo.territory_x_customer txc on customer.customer_id = txc.customer_id left join
						 Play2.dbo.territory t on txc.territory_uid = t.territory_uid
						 --P21.dbo.territory_x_customer txc on customer.customer_id = txc.customer_id left join
						 --P21.dbo.territory t on txc.territory_uid = t.territory_uid