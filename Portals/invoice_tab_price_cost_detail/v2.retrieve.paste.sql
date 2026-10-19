-- 2026-10-19 asi: price/cost columns now come from asi_fnt_invoice_price_cost and asi_fnt_invoice_line_rewards (kb_ views retired)
-- Regular Invoice 
SELECT il.invoice_no
	,il.line_no
	,il.order_no
	,il.oe_line_number AS order_line_no
	,im.item_id
	,FORMAT(il.qty_shipped,'#,##0.00') + ' ' + kb.base_unit AS qty_shipped
	,CAST(CAST(il.pricing_unit_size AS FLOAT) AS VARCHAR(75)) + ' ' + im.base_unit + ' per ' + il.pricing_unit AS packaging
	,FORMAT(ISNULL(kb.unit_price, il.unit_price), 'C') + '/' + ISNULL(kb.pricing_unit,il.pricing_unit) AS unit_price
	,FORMAT((kb.line_other_cost_home/kb.qty_shipped)*kb.pricing_unit_size,'C') + '/' + kb.pricing_unit  AS unit_cost
	,ISNULL(kb.sales_price_home,il.extended_price) AS ext_price
	,kb.line_other_cost_home AS ext_cost
	,FORMAT(kb.gross_profit_dollars,'C') AS gross_profit_dollars
	,FORMAT(CASE kb.sales_price_home WHEN 0 THEN NULL ELSE kb.gross_profit_dollars/kb.sales_price_home END,'p') AS gp_pct
	,CASE kb.pricing_method WHEN 'Manual Override' THEN 'Manual Override from ' + FORMAT(kb.system_calc_unit_price,'C') + '/' + kb.pricing_unit ELSE kb.pricing_method END AS pricing_method
	,kb.job_name as job_name
FROM invoice_line AS il
LEFT JOIN dbo.asi_fnt_invoice_price_cost(:invoice_number) AS kb ON kb.invoice_line_uid = il.invoice_line_uid
LEFT JOIN vendor_rebate ON vendor_rebate.invoice_line_uid = kb.invoice_line_uid
LEFT JOIN price_page ON kb.cost_price_page_uid = price_page.price_page_uid
LEFT JOIN inv_mast AS im ON kb.inv_mast_uid = im.inv_mast_uid
LEFT JOIN oe_line AS oel ON oel.oe_line_uid = kb.oe_line_uid
WHERE il.invoice_no = :invoice_number 
UNION
-- Automatic rewards (coop and incentive point)
SELECT 
	invoice_line.invoice_no,
	invoice_line.line_no,
	0, NULL,
	'     Reward: ' + rpv.rewards_program_id + ': ' + rpv.rewards_program_desc,
	NULL, NULL,
	FORMAT(((rpv.accumulated_incentive_points * -1.0) / invoice_line.qty_shipped) * invoice_line.pricing_unit_size,'C')
		+ '/' + invoice_line.pricing_unit,
	FORMAT((rpv.accumulated_coop_dollars / invoice_line.qty_shipped) * invoice_line.pricing_unit_size,'C')
		+ '/' + invoice_line.pricing_unit,
	(rpv.accumulated_incentive_points * -1.0),
	rpv.accumulated_coop_dollars,
	NULL, NULL, ISNULL(rpv.adjustment_reason,'')
	,'' as job_name
FROM p21_view_rewards_program_values AS rpv
LEFT JOIN invoice_line ON invoice_line.invoice_line_uid = rpv.invoice_line_uid 
WHERE invoice_line.invoice_no = :invoice_number AND rpv.row_status_flag = 704
UNION
-- OE Line rewards
SELECT 
	invoice_line.invoice_no,
	invoice_line.line_no,
	0, NULL,
	'     Reward: ' + oe_line_ud.reward_program_id + ' (manually entered): ' + ISNULL(rewards_program.rewards_program_desc,'NONE: No program matched the typed reward program ID'),
	NULL, NULL,
	FORMAT(((rw.oe_incentive_rewards * -1.0) / invoice_line.qty_shipped) * invoice_line.pricing_unit_size,'C')
		+ '/' + invoice_line.pricing_unit,
	NULL,
	(rw.oe_incentive_rewards * -1.0),
	NULL,NULL,NULL,	'Manual (entered on order)'
	,'' as job_name
FROM dbo.asi_fnt_invoice_line_rewards(:invoice_number) AS rw
LEFT JOIN invoice_line 
	ON invoice_line.invoice_no = rw.invoice_no 
	AND invoice_line.line_no = rw.line_no
LEFT JOIN oe_line_ud WITH(NOLOCK)
	ON oe_line_ud.order_no = invoice_line.order_no
	AND oe_line_ud.line_no = invoice_line.oe_line_number
LEFT JOIN rewards_program ON oe_line_ud.reward_program_id = rewards_program.rewards_program_id
WHERE invoice_line.invoice_no = :invoice_number 
	AND rw.oe_incentive_rewards <> 0.0000
UNION
-- Rebates
SELECT 
	rebates.invoice_no,
	rebates.line_no,
	0, NULL, 
	'     Rebate: ' + rebates.vendor_name, NULL, NULL,
	NULL,
	FORMAT(((rebates.rebate_due * -1.0) / invoice_line.qty_shipped) * invoice_line.pricing_unit_size,'C')
		+ '/' + invoice_line.pricing_unit,
	NULL,
	(rebates.rebate_due * -1.0),
	NULL, NULL, ''
	,'' as job_name
FROM p21_view_rebates AS rebates
LEFT JOIN invoice_line ON rebates.invoice_no = invoice_line.invoice_no AND rebates.line_no = invoice_line.line_no
WHERE rebates.invoice_no =  :invoice_number AND rebates.row_status_flag = 704 
UNION
-- Base Values
SELECT 
	shrv.invoice_no,
	shrv.line_no,
	0, NULL, 
	'     Base Prices & Costs', NULL, NULL,
	FORMAT((shrv.inflated_sales_price_home / shrv.qty_shipped) * shrv.pricing_unit_size,'C') + '/' + shrv.pricing_unit,
	FORMAT((ISNULL(rb.base_cost, shrv.deflated_line_other_cost_home) / shrv.qty_shipped) * shrv.pricing_unit_size,'C') + '/' + shrv.pricing_unit,
	shrv.inflated_sales_price_home,
	ISNULL(rb.base_cost, shrv.deflated_line_other_cost_home), NULL, NULL, '', ''
FROM dbo.asi_fnt_invoice_price_cost(:invoice_number) AS shrv
LEFT JOIN p21_view_rebates AS rb ON shrv.invoice_no = rb.invoice_no AND shrv.line_no = rb.line_no AND rb.row_status_flag = 704
WHERE shrv.invoice_no = :invoice_number 

ORDER BY line_no ASC, order_no DESC, item_id ASC

