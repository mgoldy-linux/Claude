SELECT taker.name AS taker, 
	sr.salesrep_name AS salesrep, 
	oo.location_id, 
	oo.customer_id, 
	oo.customer_name, 
	oo.order_no, 
	oo.line_no, 
	oo.item_id, 
	oo.item_desc, 
	oo.qty_open, oo.base_unit, 
	oo.open_value, 
	oo.po_no AS customer_po_no, 
	oo.order_date, pt.print_date AS pick_ticket_print_date, oel.required_date, 
	oo.disposition, oo.validation_status, oo.approved

FROM kb_view_open_orders AS oo
INNER JOIN oe_line AS oel ON oo.order_no = oel.order_no AND oo.line_no = oel.line_no
INNER JOIN oe_hdr AS oeh ON oeh.order_no = oo.order_no
LEFT JOIN users AS taker ON taker.id = oo.taker
LEFT JOIN (SELECT oept.order_no, oeptd.oe_line_no, MAX(oept.print_date) AS print_date
	FROM oe_pick_ticket AS oept 
	LEFT JOIN oe_pick_ticket_detail AS oeptd ON oeptd.pick_ticket_no = oept.pick_ticket_no
	WHERE oept.delete_flag = 'N' AND oept.printed_flag = 'Y' 
	GROUP BY oept.order_no, oeptd.oe_line_no) AS pt 
		ON pt.order_no = oo.order_no AND pt.oe_line_no = oo.line_no
LEFT JOIN kb_view_salesrep AS sr ON COALESCE(oo.updated_salesrep_id,oo.oe_salesrep_id,0) = CONVERT(VARCHAR(16),sr.salesrep_id)

WHERE oo.taker IN (
	-- Roster resolves at query time, so role changes need no portal edit.
	-- Inactive users are intentionally NOT excluded: open orders left behind by
	-- departed CSRs must stay visible so they don't go unwatched.
	-- Integration accounts are excluded so web/EDI volume does not swamp the team.
	SELECT u.id
	FROM users AS u WITH(NOLOCK)
	INNER JOIN roles AS r WITH(NOLOCK) ON r.role_uid = u.role_uid
	WHERE r.role IN ('Customer Service', 'Customer Service Manager')
	  AND u.id NOT IN ('ECOMM', 'ESTORE', 'SHAGTOOLS') )
