SELECT taker.name AS taker,
	CASE WHEN LEN(RTRIM(LTRIM(ISNULL(sr_ud.nickname,'')))) > 0
	     THEN sr_ud.nickname ELSE sr.first_name END + ' ' + sr.last_name AS salesrep,
	oeh.location_id,
	cust.customer_id,
	cust.customer_name,
	oeh.order_no,
	oel.line_no,
	im.item_id,
	im.item_desc,
	(oel.unit_quantity * oel.unit_size) - oel.qty_invoiced - oel.qty_canceled AS qty_open, im.base_unit,
	CASE COALESCE(oelud.extended_reward, 0)
		WHEN 0 THEN (oel.qty_ordered - oel.qty_invoiced - oel.qty_canceled)
			* (oel.unit_price / oel.pricing_unit_size)
		ELSE
			CASE COALESCE(oel.qty_ordered, 0)
				WHEN 0 THEN ((oel.unit_quantity * oel.unit_size) - oel.qty_invoiced - oel.qty_canceled)
					* (oel.unit_price / oel.pricing_unit_size)
				ELSE (((oel.unit_quantity * oel.unit_size) - oel.qty_invoiced - oel.qty_canceled)
					* (oel.unit_price / oel.pricing_unit_size)) - oelud.extended_reward
			END
	END AS open_value,
	oeh.po_no AS customer_po_no,
	oeh.order_date, pt.print_date AS pick_ticket_print_date, oel.required_date,
	oel.disposition, oeh.validation_status, oeh.approved

FROM oe_hdr AS oeh
INNER JOIN oe_line AS oel ON oel.order_no = oeh.order_no
-- primary_salesrep only: oe_hdr_salesrep carries split commissions (some orders have 5 reps)
-- and would otherwise multiply the order lines.
INNER JOIN oe_hdr_salesrep AS ohsr ON ohsr.order_number = oeh.order_no AND ohsr.primary_salesrep = 'Y'
LEFT JOIN customer AS cust ON cust.customer_id = oeh.customer_id
LEFT JOIN inv_mast AS im ON im.inv_mast_uid = oel.inv_mast_uid
LEFT JOIN oe_line_ud AS oelud ON oelud.order_no = oel.order_no AND oelud.line_no = oel.line_no
LEFT JOIN users AS taker ON taker.id = oeh.taker
-- Salesrep is LINE-level (oe_line_ud), which is deliberate: a line can be reassigned to a
-- different rep than the order header carries, and ~40% of open lines are. Fall back to the
-- header rep only when the line has no rep of its own -- otherwise the column comes back blank
-- even though Order Entry shows a rep (e.g. order 5920710 has no oe_line_ud row at all).
-- NULLIF guards the case where the UD field is stored as 0 rather than NULL.
LEFT JOIN contacts AS sr ON sr.id = COALESCE(
		CONVERT(VARCHAR(16), NULLIF(oelud.updated_salesrep_id, 0)),
		CONVERT(VARCHAR(16), NULLIF(oelud.oe_salesrep_id, 0)),
		ohsr.salesrep_id)
LEFT JOIN contacts_ud AS sr_ud ON sr_ud.id = sr.id
LEFT JOIN (SELECT oept.order_no, oeptd.oe_line_no, MAX(oept.print_date) AS print_date
	FROM oe_pick_ticket AS oept
	LEFT JOIN oe_pick_ticket_detail AS oeptd ON oeptd.pick_ticket_no = oept.pick_ticket_no
	WHERE oept.delete_flag = 'N' AND oept.printed_flag = 'Y'
	GROUP BY oept.order_no, oeptd.oe_line_no) AS pt
		ON pt.order_no = oeh.order_no AND pt.oe_line_no = oel.line_no

WHERE oeh.completed <> 'Y' AND oeh.projected_order <> 'Y' AND oeh.rma_flag <> 'Y'
  AND oel.complete <> 'Y' AND oel.delete_flag <> 'Y' AND oel.cancel_flag <> 'Y'
  AND oel.parent_oe_line_uid = 0
  AND oeh.taker IN (
	-- Roster resolves at query time, so role changes need no portal edit.
	-- Integration accounts are excluded so web/EDI volume does not swamp the team.
	SELECT u.id
	FROM users AS u WITH(NOLOCK)
	INNER JOIN roles AS r WITH(NOLOCK) ON r.role_uid = u.role_uid
	WHERE r.role IN ('Customer Service', 'Customer Service Manager')
	  AND u.delete_flag = 'N'
	  AND u.id NOT IN ('ECOMM', 'ESTORE', 'SHAGTOOLS') )
