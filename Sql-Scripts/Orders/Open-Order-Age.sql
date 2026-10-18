-- Open Order Age
-- Native P21 views only (no kb_/ds_/js_) -- see customer_tab_open_order_lines.srd review,
-- which showed kb_view_open_orders is just a wrapper adding nothing p21_view_oe_line doesn't
-- already expose via the "complete" flag.
--
-- "Open" line  = not complete, not cancelled, not deleted, header not a projected order/quote.
-- order_age_days      = days since the order was placed.
-- days_past_required  = days past the line's required (need-by) date; negative = not yet due.
--
-- Window is 90 days by default -- the aging-bucket breakdown (2026-09-24) showed ~96% of open
-- orders close within 90 days, so that's the real working backlog. Older orders are either
-- exceptional (worth a separate look) or dead data -- see Docs/Orphaned-Scrap-Return-Orders-
-- 2026-09-24.md for the 6 found that way. Adjust @lookback_days for a wider one-off pull.

DECLARE @lookback_days INT = 90;

SELECT
	oe_hdr.order_no,
	oe_line.line_no,
	cust.customer_id,
	cust.customer_name,
	oe_hdr.order_date,
	DATEDIFF(DAY, oe_hdr.order_date, GETDATE())      AS order_age_days,
	oe_line.required_date,
	DATEDIFF(DAY, oe_line.required_date, GETDATE())  AS days_past_required,
	oe_line.item_id,
	oe_line.qty_ordered,
	oe_hdr.validation_status,
	oe_hdr.approved
FROM p21_view_oe_hdr oe_hdr
	INNER JOIN p21_view_oe_line oe_line
		ON oe_line.order_no = oe_hdr.order_no
	INNER JOIN p21_view_customer cust
		ON cust.customer_id = oe_hdr.customer_id
		AND cust.company_id = oe_hdr.company_id
WHERE
	oe_hdr.delete_flag         = 'N'
	AND oe_hdr.projected_order = 'N'
	AND oe_hdr.cancel_flag     = 'N'
	AND oe_line.delete_flag    = 'N'
	AND oe_line.complete       = 'N'
	AND oe_line.parent_oe_line_uid = 0
	-- AND oe_hdr.rma_flag      = 'N'  -- portal's own query leaves RMAs in by default; uncomment to exclude
	AND oe_hdr.order_date >= DATEADD(DAY, -@lookback_days, GETDATE())
ORDER BY order_age_days DESC;
