SELECT        c.legacy_id AS customer_legacy_id, COALESCE (c.customer_name, 'unknown') AS CustName, invoice_hdr.disputed_flag AS Disputed, invoice_hdr.original_document_type AS OrgDocType, invoice_hdr.consolidated AS Cnsldtd, 
                         COALESCE (c.sic_code, 0) AS SIC, COALESCE (c.salesrep_id, 0) AS CustSalesRepId, c.class_1id AS CustClass1, c.class_2id AS CustClass2, c.credit_limit, c.credit_limit_used, c.ar_account_no, c.revenue_account_no, 
                         c.cos_account_no, c.allowed_account_no, c.terms_account_no, c.customer_id_string, c.freight_account_no, c.brokerage_account_no, c.class_3id, c.class_4id, c.class_5id, c.accept_partial_orders, c.last_check_number, 
                         c.last_check_amount, c.receivable_group_id, c.order_acknowledgments, c.minimum_finance_charge, c.po_no_required, c.delete_flag AS CustomerdeleteFlag, c.highest_credit_limit_used, c.credit_status, CONVERT(datetime, 
                         CONVERT(char(10), c.date_acct_opened, 120), 120) AS AcctOpenDt, CONVERT(datetime, CONVERT(char(10), c.last_check_date, 120), 120) AS last_check_date, COALESCE (invoice_hdr.salesrep_id, 0) AS salesrepidorder, 
                         CONVERT(datetime, CONVERT(char(10), invoice_hdr.date_created, 120), 120) AS DateCreated, invoice_hdr.company_no, invoice_hdr.customer_id, invoice_hdr.order_no AS OrdNum, COALESCE (invoice_hdr.salesrep_id, 0) 
                         AS InvSalesRepId, invoice_hdr.invoice_type AS InvType, COALESCE (invoice_hdr.corp_address_id, invoice_hdr.customer_id, 0) AS CorpAddrId, COALESCE (invoice_hdr.ship_to_id, 0) AS ShipToId, 
                         invoice_hdr.period AS FiscalPeriod, invoice_hdr.invoice_period AS invoiceperiod, invoice_hdr.year_for_period AS FiscalYear, invoice_hdr.store_no AS StoreNum, invoice_hdr.ar_account_no AS ARacctNum, 
                         invoice_hdr.po_no AS POnum, invoice_hdr.paid_in_full_flag AS PaidInFull, invoice_hdr.paid_by_check_no AS PaidByCheckNum, invoice_hdr.invoice_reference_no AS RefNum, invoice_hdr.invoice_desc AS InvDescription, 
                         invoice_hdr.sales_location_id AS LocId, invoice_hdr.sold_to_customer_id AS SoldToID, invoice_hdr.statement_period AS StmntPeriod, invoice_hdr.statement_year AS StmntYear, invoice_hdr.invoice_no AS invnum, 
                         invoice_hdr.allowed_home AS Allwd, invoice_hdr.company_no AS Company, COALESCE (invoice_hdr.customer_id_number, 0) AS CustIDNum, invoice_hdr.customer_id AS CustId, invoice_hdr.branch_id, 
                         COALESCE (invoice_hdr.branch_id, '0') AS Branch, invoice_hdr.bill2_name, invoice_hdr.bill2_contact, invoice_hdr.bill2_address1, invoice_hdr.bill2_address2, invoice_hdr.bill2_state, invoice_hdr.bill2_postal_code, 
                         invoice_hdr.ship2_name, invoice_hdr.bill2_city, invoice_hdr.ship2_contact, invoice_hdr.ship2_address1, invoice_hdr.ship2_address2, invoice_hdr.invoice_adjustment_type AS InvAdjType, 
                         invoice_hdr.invoice_class AS InvClass, invoice_hdr.approved AS Apprvd, invoice_hdr.ship2_city, invoice_hdr.ship2_state, invoice_hdr.ship2_postal_code, COALESCE (invoice_hdr.carrier_name, 'Blank') AS Carrier_name, 
                         invoice_hdr.fob, invoice_hdr.freight, invoice_hdr.terms_taken, invoice_hdr.period_fully_paid AS PeriodFullyPaid, invoice_hdr.year_fully_paid AS YearFullyPaid, invoice_hdr.ship2_email_address, invoice_hdr.ship_to_phone, 
                         invoice_hdr.period, invoice_hdr.year_for_period, COALESCE (invoice_hdr.total_amount_home, 0) AS TotAmount, COALESCE (invoice_hdr.amount_paid_home, 0) AS Paid, COALESCE (invoice_hdr.memo_amount_home, 0) 
                         AS MemoAmt, COALESCE (invoice_hdr.other_charge_amount_home, 0) AS OtherChgAmt, COALESCE (invoice_hdr.tax_amount_home, 0) AS TaxAmt, COALESCE (invoice_hdr.terms_amount_home, 0) AS TermsAmt, 
                         CONVERT(datetime, CONVERT(char(10), invoice_hdr.order_date, 120), 120) AS OrdDate, CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120) AS InvDate, CONVERT(datetime, CONVERT(char(10), 
                         invoice_hdr.ship_date, 120), 120) AS ShipDate, CONVERT(datetime, CONVERT(char(10), invoice_hdr.date_paid, 120), 120) AS DatePaid, CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120) 
                         AS NetDueDate, CONVERT(datetime, CONVERT(char(10), invoice_hdr.terms_due_date, 120), 120) AS TermsDueDate, COALESCE (contacts_1.last_name + ',' + contacts_1.first_name, 'unknown') AS InvSalesRepName, 
                         COALESCE (cnt.last_name + ', ' + cnt.first_name, 'unknown') AS CustSalesRepName, cnt.delete_flag AS ContactsDeleteFlag, COALESCE (contactsShip.last_name + ',' + contactsShip.first_name, 'unknown') 
                         AS Ship2SalesRepName, CASE WHEN Class.Class_description IS NULL THEN 'blank' ELSE Class.Class_description END AS Class1Desc, CASE WHEN Class2.Class_description IS NULL 
                         THEN 'blank' ELSE Class2.Class_description END AS Class2Desc, CASE WHEN Class3.Class_description IS NULL THEN 'blank' ELSE Class3.Class_description END AS Class3DEsc, 
                         CASE WHEN Class4.Class_description IS NULL THEN 'blank' ELSE Class4.Class_description END AS Class4Desc, CASE WHEN Class5.Class_description IS NULL 
                         THEN 'blank' ELSE Class5.Class_description END AS Class5DEsc, COALESCE (terms.terms_desc, 'Blank') AS CustomerTerms, COALESCE (hdrterms.terms_desc, 'Blank') AS Terms_Desc, location.location_name, 
                         b.branch_description AS BranchName, Company.company_name, ISNULL(corp.address_name, c.customer_name) AS corpaddname, ship_to_salesrep.salesrep_id AS shipSalesRep, FS.AvgDaystoPay, 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END AS ExpectedDate, DATEDIFF(day, 
                         CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) AS PastDueDays, DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) 
                         AS PastDueDaysInv, CASE WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) >= 91 THEN 4 WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         invoice_hdr.net_due_date, 120), 120), GETDATE()) BETWEEN 61 AND 90 THEN 3 WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) BETWEEN 31 AND 
                         60 THEN 2 WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) BETWEEN 1 AND 30 THEN 1 ELSE '0' END AS Age_no, CASE WHEN DATEDIFF(day, 
                         CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) >= 91 THEN 4 WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) BETWEEN
                          61 AND 90 THEN 3 WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) BETWEEN 31 AND 60 THEN 2 WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         invoice_hdr.invoice_date, 120), 120), GETDATE()) <= 30 THEN 1 END AS InvAge_no, CASE WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) 
                         >= 91 THEN 'Over 90 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) BETWEEN 61 AND 90 THEN '61 -90 Days' WHEN DATEDIFF(day, CONVERT(datetime, 
                         CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) BETWEEN 31 AND 60 THEN '31 - 60 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.net_due_date, 120), 120), GETDATE()) 
                         BETWEEN 1 AND 30 THEN '1 - 30 Days' ELSE 'Current' END AS Age, CASE WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) 
                         >= 91 THEN 'Over 90 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) BETWEEN 61 AND 90 THEN '61 -90 Days' WHEN DATEDIFF(day, CONVERT(datetime, 
                         CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) BETWEEN 31 AND 60 THEN '31 - 60 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), invoice_hdr.invoice_date, 120), 120), GETDATE()) 
                         <= 30 THEN '1 - 30 Days' END AS InvAge, CASE WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) 
                         * 1 >= 10 THEN '10 + Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) * 1 BETWEEN 7 AND 
                         9 THEN '7 - 9 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) * 1 BETWEEN 4 AND 
                         6 THEN '4 - 6 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) 
                         * 1 <= 3 THEN '0 - 3 Days' END AS Agedby3Days, CASE WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) 
                         * 1 >= 22 THEN '22 + Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, round(fs.AvgDaystoPay, 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) * 1 BETWEEN 15 AND 
                         21 THEN '15 - 21 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) * 1 BETWEEN 8 AND 
                         14 THEN '8 - 14 Days' WHEN DATEDIFF(day, CONVERT(datetime, CONVERT(char(10), 
                         CASE WHEN CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END > 0 THEN DateAdd(dd, COALESCE (round(fs.AvgDaystoPay, 0), 0), net_due_date) ELSE '' END, 120), 120), GETDATE()) 
                         * 1 <= 7 THEN '0 - 7 Days' END AS Agedby7Days, CASE WHEN invoice_hdr.paid_in_full_flag = 'y' THEN 0 ELSE round(invoice_hdr.total_amount_home - (invoice_hdr.amount_paid_home + terms_taken_home) 
                         + invoice_hdr.memo_amount_home + invoice_hdr.bad_debt_amount_home, 2) END AS BalanceDue, CASE WHEN contactsShip.id IN
                             (SELECT DISTINCT sales_manager_id
                               FROM            p21.dbo.contacts
                               WHERE        salesrep = 'y' AND delete_flag = 'n' AND sales_manager_id IS NOT NULL) 
                         THEN contactsShip.last_name + ', ' + contactsShip.first_name ELSE manager.last_name + ', ' + manager.first_name END AS Sales_Manager,c.days_overdue_for_credit_hold -- I added this
FROM            Play2.dbo.p21_view_invoice_hdr AS invoice_hdr LEFT OUTER JOIN
                         Play2.dbo.customer AS c ON invoice_hdr.customer_id = c.customer_id AND invoice_hdr.company_no = c.company_id LEFT OUTER JOIN
                         Play2.dbo.location AS location WITH (nolock) ON location.location_id = invoice_hdr.sales_location_id AND location.company_id = invoice_hdr.company_no LEFT OUTER JOIN
                         Play2.dbo.branch AS b WITH (nolock) ON invoice_hdr.company_no = b.company_id AND invoice_hdr.branch_id = b.branch_id LEFT OUTER JOIN
                         Play2.dbo.contacts AS cnt WITH (nolock) ON c.salesrep_id = cnt.id LEFT OUTER JOIN
                         Play2.dbo.contacts AS contacts_1 WITH (nolock) ON contacts_1.id = invoice_hdr.salesrep_id LEFT OUTER JOIN
                         Play2.dbo.terms AS terms WITH (nolock) ON terms.terms_id = c.terms_id AND terms.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.terms AS hdrterms WITH (nolock) ON hdrterms.terms_id = invoice_hdr.terms_id AND hdrterms.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS Class WITH (nolock) ON c.class_1id = Class.class_id AND Class.class_number = 1 AND Class.class_type = 'cs' AND Class.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS Class2 WITH (nolock) ON c.class_2id = Class2.class_id AND Class2.class_number = 2 AND Class2.class_type = 'cs' AND Class2.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS Class3 WITH (nolock) ON c.class_3id = Class3.class_id AND Class3.class_number = 3 AND Class3.class_type = 'cs' AND Class3.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS Class4 WITH (nolock) ON c.class_4id = Class4.class_id AND Class4.class_number = 4 AND Class4.class_type = 'cs' AND Class4.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.class AS Class5 WITH (nolock) ON c.class_5id = Class5.class_id AND Class5.class_number = 5 AND Class5.class_type = 'cs' AND Class5.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.company AS Company WITH (nolock) ON invoice_hdr.company_no = Company.company_id LEFT OUTER JOIN
                         Play2.dbo.corp_id AS corp WITH (nolock) ON corp.address_id = invoice_hdr.corp_address_id AND corp.company_id = invoice_hdr.company_no LEFT OUTER JOIN
                         Play2.dbo.ship_to_salesrep AS ship_to_salesrep ON ship_to_salesrep.ship_to_id = invoice_hdr.ship_to_id AND ship_to_salesrep.company_id = invoice_hdr.company_no AND ship_to_salesrep.primary_salesrep = 'y' AND 
                         ship_to_salesrep.delete_flag = 'n' LEFT OUTER JOIN
                         Play2.dbo.contacts AS contactsShip ON ship_to_salesrep.salesrep_id = contactsShip.id LEFT OUTER JOIN
                         P21.dbo.contacts AS manager WITH (nolock) ON manager.id = contactsShip.sales_manager_id LEFT OUTER JOIN
                             (SELECT        h2.company_no, h2.customer_id, COALESCE (SUM(DATEDIFF(dd, h2.net_due_date, ar_receipts.date_received) * ar_receipts_detail.payment_amount) / NULLIF (SUM(ar_receipts_detail.payment_amount), 0), 0) 
                                                         AS AvgDaystoPay
                               FROM            Play2.dbo.invoice_hdr AS h2 INNER JOIN
                                                         Play2.dbo.ar_receipts_detail AS ar_receipts_detail ON ar_receipts_detail.invoice_no = h2.invoice_no INNER JOIN
                                                         Play2.dbo.ar_receipts AS ar_receipts ON ar_receipts.receipt_number = ar_receipts_detail.receipt_number
                               WHERE        (CONVERT(datetime, CONVERT(char(10), ar_receipts.date_received, 120), 120) <= GETDATE()) AND (CONVERT(datetime, CONVERT(char(10), ar_receipts.date_received, 120), 120) >= DATEADD(yy, - 1, GETDATE()))
                               GROUP BY h2.company_no, h2.customer_id) AS FS ON FS.company_no = invoice_hdr.company_no AND FS.customer_id = invoice_hdr.customer_id
WHERE        (invoice_hdr.paid_in_full_flag = 'n') AND (invoice_hdr.consolidated <> 'Y') AND (invoice_hdr.total_amount - (invoice_hdr.amount_paid + invoice_hdr.terms_taken) 
                         + invoice_hdr.memo_amount + invoice_hdr.bad_debt_amount <> 0)