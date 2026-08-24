-- email from Clark, query creates duplicates
-- 07/05/2022 Clark verbally all vendors

SELECT vendor.vendor_name, apinv_hdr.voucher_no, apinv_hdr.invoice_no,m.item_id,ff.qty_received,ff.fifo_layer_qty[QtyOpen],ff.cost/*,
		CASE WHEN vendor .vendor_type_cd = 2980 THEN 'Expense' 
		WHEN vendor .vendor_type_cd = 2981 THEN 'Inventory' 
		WHEN vendor .vendor_type_cd = 2982 THEN 'Both' ELSE CAST(vendor .vendor_type_cd AS varchar(1000)) END AS Vendor_type,
		apinv_hdr.company_no, apinv_hdr.vendor_id, apinv_hdr.branch_id, apinv_hdr.company_no AS Company, apinv_hdr.vendor_id AS Vendor, apinv_hdr.branch_id AS Branch, 
                         branch.branch_description AS BranchName,  CONVERT(datetime, CONVERT(char(10), apinv_hdr.invoice_date, 120), 120) AS InvoiceDate, apinv_hdr.invoice_amount AS InvoiceAmount, 
                         CONVERT(datetime, CONVERT(char(10), apinv_hdr.net_due_date, 120), 120) AS NetDueDate, CONVERT(datetime, CONVERT(char(10), apinv_hdr.terms_due_date, 120), 120) AS TermsDueDate, 
                         apinv_hdr.terms_amount AS TermsAmount, apinv_hdr.ap_account_no AS APAcctNo, apinv_hdr.amount_paid AS AmountPaid, apinv_hdr.terms_amount_taken AS TermsAmountTaken, apinv_hdr.paid_in_full AS PaidInFull, 
                         apinv_hdr.po_no AS PONumber, apinv_hdr.terms_taken_account AS TermsTakenAccount, apinv_hdr.disputed_flag AS Disputed, apinv_hdr.check_no AS CheckNo, CONVERT(datetime, CONVERT(char(10), apinv_hdr.check_date, 
                         120), 120) AS CheckDate, apinv_hdr.memo_amount AS MemoAmount, apinv_hdr.approved, CONVERT(datetime, CONVERT(char(10), apinv_hdr.date_created, 120), 120) AS date_created, apinv_hdr.period, 
                         apinv_hdr.year_for_period, apinv_hdr.voucher_no, DATEDIFF(day, apinv_hdr.net_due_date, GETDATE()) AS PastDueDays, CASE WHEN DATEDIFF(day, net_due_date, GETDATE()) 
                         >= 91 THEN 'Over 90 Days' WHEN DATEDIFF(day, net_due_date, GETDATE()) BETWEEN 61 AND 90 THEN '61 - 90 Days' WHEN DATEDIFF(day, net_due_date, GETDATE()) BETWEEN 31 AND 
                         60 THEN '31 - 60 Days' ELSE '0 - 30 Days' END AS Age, CASE WHEN DATEDIFF(day, net_due_date, GETDATE()) >= 91 THEN 3 WHEN DATEDIFF(day, net_due_date, GETDATE()) BETWEEN 61 AND 
                         90 THEN 2 WHEN DATEDIFF(day, net_due_date, GETDATE()) BETWEEN 31 AND 60 THEN 1 ELSE 0 END AS Age_no, 
                         CASE WHEN disputed_flag = 'Y' THEN 0 ELSE apinv_hdr.invoice_amount - apinv_hdr.amount_paid - apinv_hdr.terms_amount_taken + apinv_hdr.memo_amount END AS OpenAmount, 
                         CASE WHEN disputed_flag = 'Y' THEN apinv_hdr.invoice_amount - apinv_hdr.amount_paid - apinv_hdr.terms_amount_taken + apinv_hdr.memo_amount ELSE 0 END AS DisputedAmount, ISNULL(payments.cleared_bank, 'U') 
                         AS cleared_bank, payments.cleared_period, payments.cleared_year, CONVERT(datetime, CONVERT(char(10), payments.date_last_modified, 120), 120) AS date_last_modified, payments.last_maintained_by, 
                         payment_detail.bank_no, COALESCE (vclass.class_description, 'Blank') AS vClass1, COALESCE (vCLass2.class_description, 'Blank') AS vClass2, COALESCE (vCLass3.class_description, 'Blank') AS vClass3, 
                         COALESCE (vCLass4.class_description, 'Blank') AS vClass4, COALESCE (vCLass5.class_description, 'Blank') AS vClass5, vendor.vendor_name AS VendorName, Company.company_name, po.location_id*/
FROM            P21.dbo.apinv_hdr AS apinv_hdr WITH (nolock) 
				LEFT OUTER JOIN P21.dbo.po_hdr AS po 
				ON CAST(po.po_no AS varchar(100)) = apinv_hdr.po_no 
				LEFT OUTER JOIN
                         P21.dbo.company AS Company WITH (nolock) ON apinv_hdr.company_no = Company.company_id INNER JOIN
                         P21.dbo.vendor AS vendor WITH (nolock) ON apinv_hdr.company_no = vendor.company_id AND apinv_hdr.vendor_id = vendor.vendor_id INNER JOIN
                         P21.dbo.branch AS branch WITH (nolock) ON apinv_hdr.company_no = branch.company_id AND apinv_hdr.branch_id = branch.branch_id LEFT OUTER JOIN
                         P21.dbo.payment_detail AS payment_detail ON apinv_hdr.voucher_no = payment_detail.voucher_no AND apinv_hdr.check_no = payment_detail.check_no LEFT OUTER JOIN
                         P21.dbo.payments AS payments ON payment_detail.company_no = payments.company_no AND payment_detail.bank_no = payments.bank_no AND payment_detail.check_no = payments.check_no LEFT OUTER JOIN
                         P21.dbo.class AS vclass WITH (nolock) ON vendor.class_1id = vclass.class_id AND vclass.class_number = 1 AND vclass.class_type = 'vd' AND vclass.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS vCLass2 WITH (nolock) ON vendor.class_2id = vCLass2.class_id AND vCLass2.class_number = 2 AND vCLass2.class_type = 'vd' AND vCLass2.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS vCLass3 WITH (nolock) ON vendor.class_3id = vCLass3.class_id AND vCLass3.class_number = 3 AND vCLass3.class_type = 'vd' AND vCLass3.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS vCLass4 WITH (nolock) ON vendor.class_4id = vCLass4.class_id AND vCLass4.class_number = 4 AND vCLass4.class_type = 'vd' AND vCLass4.delete_flag = 'n' LEFT OUTER JOIN
                         P21.dbo.class AS vCLass5 WITH (nolock) ON vendor.class_4id = vCLass5.class_id AND vCLass5.class_number = 5 AND vCLass5.class_type = 'vd' AND vCLass5.delete_flag = 'n'
			    left join P21.dbo.po_line pl
				on po.po_no = pl.po_no and apinv_hdr.po_no =  CAST(pl.po_no  AS varchar(100))
				left join P21.dbo.fifo_layers ff
				on pl.inv_mast_uid = ff.inv_mast_uid and year(ff.date_received) = year(pl.received_date) and month(ff.date_received) = month(pl.received_date) and day(ff.date_received) = day(pl.received_date)
				join inv_mast m
				on pl.inv_mast_uid = m.inv_mast_uid
--Where apinv_hdr.invoice_no like 'CP%'-- and  item_id = '39A080001'
--order by InvoiceDate Desc