-- SA 57068 (follow-on): purchasing_open_backorders_mine_nonsamples retrieve= with kb_view_oe_line_po and kb_view_carrier removed.
-- Proven EXCEPT-equivalent to the live Prod query 10/15/2026 for CPOLAK 300, RBONATO 1234, ZMORIN 556, ADIERKS 109, JTIEHEN 126 (both directions 0).
-- Reads (IO stats): CPOLAK 972K -> 40K, RBONATO 1.006M -> 102K; CPU about the same. NOT deployed. Paste into InfoMaker as the retrieve= SQL.
-- kb_view_oe_line_po -> p21_view_oe_line_po + vessel_receipts_line/po_line mapping for connection_type 'V' (same as the KB view); kb_view_carrier -> p21_view_address (carrier_flag = 'Y').
----------------------- 
-- Created by Karen Benish
-- May 27, 2016
-- Shows all order lines with disposition backorder 
--	includes linked POs, all credit status orders
-- Includes everything except item class 2 of samples
----------------------- 
DECLARE @buyer_id AS INTEGER
SET @buyer_id = (SELECT contact_id FROM p21_view_users WHERE id = '<user_id>')
SELECT p21_view_oe_hdr.customer_id
	,p21_view_customer.customer_name
	,p21_view_oe_line.source_loc_id AS source_loc
	,p21_view_inv_loc.product_group_id AS prod_group
	,p21_view_inv_mast.class_id1 AS mfg
	,p21_view_oe_hdr.order_no
	,p21_view_oe_line.line_no
	,p21_view_oe_hdr.validation_status AS ord_status
	,COALESCE(CAST(olp.po_no AS VARCHAR), '') AS po_no
	,p21_view_inv_mast.track_lots
	,p21_view_oe_line.item_id
	,p21_view_inv_mast.item_desc
	,p21_view_oe_line.qty_ordered
	,p21_view_oe_line.qty_allocated
--	,p21_view_oe_line.qty_canceled
--	,p21_view_oe_line.qty_invoiced
	,p21_view_inv_loc.qty_on_hand AS qty_on_hand_at_loc
	,total_inv_loc.total_qty_on_hand
	,COALESCE((SELECT SUM(po_l.qty_ordered) AS qty_ordered FROM p21_view_po_hdr AS po_h  
		LEFT JOIN p21_view_po_line AS po_l ON po_h.po_no = po_l.po_no AND po_l.complete = 'N' AND po_l.delete_flag <> 'Y'
		LEFT JOIN p21_view_inv_mast AS inv_m ON po_l.item_id = inv_m.item_id AND inv_m.delete_flag <> 'Y'
		WHERE po_h.complete = 'N' AND po_h.po_type <> 'Q' AND inv_m.item_id = p21_view_inv_mast.item_id
		GROUP BY inv_m.item_id
	),0) AS total_qty_open_on_pos
	,purchaser.first_name AS buyer
	,p21_view_po_hdr.expected_date
	,p21_view_po_line.date_due
	,p21_view_oe_hdr.requested_date AS required_date
	,carrier.[name] AS carrier_name
	
FROM p21_view_oe_line
LEFT JOIN p21_view_inv_mast
	ON p21_view_oe_line.inv_mast_uid = p21_view_inv_mast.inv_mast_uid
LEFT JOIN p21_view_inv_loc
	ON p21_view_oe_line.inv_mast_uid = p21_view_inv_loc.inv_mast_uid
	AND p21_view_oe_line.source_loc_id = p21_view_inv_loc.location_id
LEFT JOIN (
	SELECT inv_mast_uid, SUM(qty_on_hand) AS total_qty_on_hand
	FROM p21_view_inv_loc 
	GROUP BY inv_mast_uid
	) AS total_inv_loc
	ON total_inv_loc.inv_mast_uid = p21_view_oe_line.inv_mast_uid
LEFT JOIN p21_view_oe_hdr
	ON p21_view_oe_hdr.order_no = p21_view_oe_line.order_no
LEFT JOIN p21_view_customer	
	ON p21_view_customer.customer_id = p21_view_oe_hdr.customer_id
	AND p21_view_customer.company_id = p21_view_oe_hdr.company_id
--LEFT JOIN p21_view_oe_line_po
--	ON p21_view_oe_line_po.order_number = p21_view_oe_line.order_no
--	AND p21_view_oe_line_po.line_number = p21_view_oe_line.line_no
--	AND p21_view_oe_line_po.delete_flag = 'N'
--	-- Should I pull these two out?
--	AND p21_view_oe_line_po.cancel_flag = 'N'
--	AND p21_view_oe_line_po.completed = 'N'
LEFT JOIN p21_view_oe_line_po
	ON p21_view_oe_line_po.order_number = p21_view_oe_line.order_no
	AND p21_view_oe_line_po.line_number = p21_view_oe_line.line_no 
	AND p21_view_oe_line_po.delete_flag = 'N'
	AND p21_view_oe_line_po.cancel_flag = 'N'
-- vessel-receipt links (connection_type 'V') carry a receipt number in po_no; map them to the real PO line (same mapping the old KB view did)
LEFT JOIN p21_view_vessel_receipts_line AS vrl
	ON p21_view_oe_line_po.connection_type = 'V'
	AND CONVERT(DECIMAL(19,0), vrl.vessel_receipts_hdr_uid) = p21_view_oe_line_po.po_no
	AND CONVERT(DECIMAL(19,0), vrl.line_no) = p21_view_oe_line_po.po_line_number
LEFT JOIN p21_view_po_line AS vpl
	ON vpl.po_line_uid = vrl.po_line_uid
	AND vpl.delete_flag <> 'Y'
	AND vpl.cancel_flag <> 'Y'
CROSS APPLY (SELECT CASE p21_view_oe_line_po.connection_type WHEN 'V' THEN vpl.po_no ELSE p21_view_oe_line_po.po_no END AS po_no
		, CASE p21_view_oe_line_po.connection_type WHEN 'V' THEN vpl.line_no ELSE p21_view_oe_line_po.po_line_number END AS po_line_no) AS olp
LEFT JOIN p21_view_supplier
	ON p21_view_oe_line.supplier_id = p21_view_supplier.supplier_id
LEFT JOIN p21_view_contacts AS purchaser
	ON p21_view_supplier.buyer_id = purchaser.id
LEFT JOIN p21_view_po_hdr 
	ON p21_view_po_hdr.po_no = olp.po_no
LEFT JOIN p21_view_po_line
	ON p21_view_po_line.po_no = olp.po_no
	AND p21_view_po_line.line_no = olp.po_line_no
LEFT JOIN p21_view_address AS carrier
	ON p21_view_oe_hdr.carrier_id = carrier.id
	AND carrier.carrier_flag = 'Y'
	
WHERE 
	-- Omit deleted, RMA, quotes, complete, not yet approved estore orders
	COALESCE(p21_view_oe_line.delete_flag,'N') = 'N'
	AND COALESCE(p21_view_oe_hdr.delete_flag,'N') = 'N'
	AND p21_view_oe_hdr.rma_flag = 'N' 
    AND p21_view_oe_hdr.projected_order = 'N'
	AND p21_view_oe_line.complete = 'N'
	AND p21_view_oe_hdr.approved = 'Y'	
	-- Include only backorders that are not samples/displays
	AND (p21_view_inv_mast.class_id2 IS NULL OR p21_view_inv_mast.class_id2 <> 'SAMPLES')
	AND p21_view_oe_line.disposition = 'B'
	-- Omit bill only carrier
	AND ISNULL(p21_view_oe_hdr.carrier_id,0) <> 3001102 
	AND p21_view_supplier.buyer_id = @buyer_id

ORDER BY COALESCE(CAST(olp.po_no AS VARCHAR), '') ASC
	,p21_view_oe_line.source_loc_id ASC
	,p21_view_inv_loc.product_group_id ASC
	,p21_view_inv_mast.class_id1 ASC