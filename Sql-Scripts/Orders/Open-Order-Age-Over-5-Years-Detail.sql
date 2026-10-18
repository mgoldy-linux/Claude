-- Drill-down on the 6 open orders found in the "8: 5+ years" bucket
-- (Open-Order-Age-Summary.sql, run with @lookback_years wide open).
--
-- Goal: tell genuinely stuck/orphaned orders apart from long-running legitimate ones
-- (e.g. a job-tied order with a real multi-year required_date, or a line partially
-- shipped/invoiced that just never got marked complete).
--
-- invoice_status is the key signal: 'Never invoiced' after 5+ years open, with no
-- validation/approval movement, is the strongest orphan indicator here.

SELECT
	oe_hdr.order_no,
	oe_hdr.order_date,
	DATEDIFF(DAY, oe_hdr.order_date, GETDATE())  AS order_age_days,
	oe_hdr.customer_id,
	cust.customer_name,
	oe_hdr.po_no,
	oe_hdr.validation_status,
	oe_hdr.approved,
	oe_hdr.taker,
	oe_hdr.job_name,
	oe_line.line_no,
	oe_line.item_id,
	inv_mast.extended_desc,
	oe_line.qty_ordered,
	oe_line.disposition,
	oe_line.complete,
	oe_line.required_date,
	inv.invoice_no,
	inv.unit_price_home,
	CASE WHEN inv.invoice_no IS NULL THEN 'Never invoiced' ELSE 'Has invoice activity' END AS invoice_status
FROM p21_view_oe_hdr oe_hdr
	INNER JOIN p21_view_oe_line oe_line
		ON oe_line.order_no = oe_hdr.order_no
		AND oe_line.parent_oe_line_uid = 0
	INNER JOIN p21_view_customer cust
		ON cust.customer_id = oe_hdr.customer_id
		AND cust.company_id  = oe_hdr.company_id
	LEFT JOIN p21_view_inv_mast inv_mast
		ON inv_mast.inv_mast_uid = oe_line.inv_mast_uid
	LEFT JOIN p21_view_invoice_line inv
		ON inv.order_no        = oe_line.order_no
		AND inv.oe_line_number = oe_line.line_no
WHERE
	oe_hdr.delete_flag         = 'N'
	AND oe_hdr.projected_order = 'N'
	AND oe_hdr.cancel_flag     = 'N'
	AND oe_line.delete_flag    = 'N'
	AND oe_line.complete       = 'N'
	AND oe_hdr.order_date < DATEADD(YEAR, -5, GETDATE())
ORDER BY oe_hdr.order_date, oe_hdr.order_no, oe_line.line_no;
