USE [P21Play]
GO

/*
=====================================================================================================
 dbo.asi_view_rebill_invoices
 Verbatim port of dbo.kb_view_rebill_invoices (KB, 2020-03-03) -- logic unchanged, it already reads only
 native objects (invoice_hdr, p21_view_rebill_invoice). The kb_ view is left in place.
 Used by: asi_sales_history_report_view_roii_costs (direct_flag).

 One row per invoice in a rebill chain, with the chain's original invoice:
   0 = original invoice, 1 = negative intermediate (credit, source_type_cd 2638),
   2 = positive intermediate (rebilled more than once), 5 = final rebill (record_type_cd 2594 = "Rebill Invoice")
 Created 2026-10-02 Mark Goldyn.
=====================================================================================================
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW dbo.asi_view_rebill_invoices
AS
WITH positive_rebill_invoices AS (
	SELECT DISTINCT invoice_hdr.invoice_no AS rebill_invoice_no,
		invoice_hdr.record_type_reference_no AS original_invoice_no,
		CASE WHEN lih.latest_rebill_invoice_no IS NULL THEN 'N' ELSE 'Y' END AS final_rebill_flag,
		invoice_date
	-- rebilled invoice
	FROM invoice_hdr
	-- latest invoice rebill header
	LEFT JOIN p21_view_rebill_invoice AS lih
		ON lih.latest_rebill_invoice_no = invoice_hdr.invoice_no
	-- record type cd 2594 is "Rebill Invoice"
	WHERE invoice_hdr.record_type_cd = 2594
),
negative_intermediate_invoices AS (
	SELECT nii.invoice_no,
		COALESCE(pri.original_invoice_no, nii.invoice_reference_no) AS original_invoice_no,
		nii.invoice_date
	FROM invoice_hdr AS nii
	LEFT JOIN positive_rebill_invoices AS pri ON pri.rebill_invoice_no = nii.invoice_reference_no
	WHERE nii.invoice_reference_no IS NOT NULL
		AND nii.source_type_cd = 2638
),
original_invoices AS (
	SELECT DISTINCT ih.record_type_reference_no AS invoice_no,
		original.invoice_date
	FROM invoice_hdr AS ih
	INNER JOIN invoice_hdr AS original ON original.invoice_no = ih.record_type_reference_no
	WHERE ih.record_type_cd = 2594
),
all_invoices AS (
	SELECT rebill_invoice_no AS invoice_no,
		CASE WHEN final_rebill_flag = 'Y' THEN 5 ELSE 2 END AS invoice_type,
		original_invoice_no,
		invoice_date
	FROM positive_rebill_invoices
	UNION
	SELECT invoice_no AS invoice_no,
		0 AS invoice_type,
		invoice_no AS original_invoice_no,
		invoice_date
	FROM original_invoices
	UNION
	SELECT invoice_no AS invoice_no,
		1 AS invoice_type,
		original_invoice_no,
		invoice_date
	FROM negative_intermediate_invoices
)

SELECT
	all_invoices.invoice_no
	,ih.order_no
	,ih.date_created
	,all_invoices.invoice_date
	,all_invoices.invoice_type AS invoice_revision_type_code
	,CASE all_invoices.invoice_type
		WHEN 0 THEN 'Original invoice in rebill'
		WHEN 1 THEN 'Negative intermediate step in rebill'
		WHEN 2 THEN 'Positive intermediate step (has been rebilled more than once)'
		WHEN 5 THEN 'Final step in rebill'
		ELSE NULL
		END AS invoice_revision_type_desc
	,all_invoices.original_invoice_no
	,original_ih.order_no AS original_order_no
FROM all_invoices
INNER JOIN invoice_hdr AS ih ON ih.invoice_no = all_invoices.invoice_no
INNER JOIN invoice_hdr AS original_ih
	ON original_ih.invoice_no = all_invoices.original_invoice_no
GO

GRANT SELECT ON dbo.asi_view_rebill_invoices TO p21_application_role
GO
GRANT SELECT ON dbo.asi_view_rebill_invoices TO PxxiUser
GO
