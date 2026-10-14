-- SA 57068: purchasing_open_BO_age retrieve= rewrite (no kb_ views, no audit-view CASE overhead)
-- Same output columns/order as the current portal. <user_id> is the P21 portal token.
-- Changes: kb_view_open_orders -> oe_hdr/oe_line direct (same filters as the view);
--          inv_loc/pending-qty derived tables no longer span the whole system (OUTER APPLY keyed on the BO line);
--          p21_view_audit_trail_oe_hdr_1319 -> audit_trail, narrowed to column_changed='disposition' + uid range (see below).
DECLARE @buyer_id AS VARCHAR(7)
SET @buyer_id = (SELECT ISNULL(contact_id, '%') FROM p21_view_users WHERE id = '<user_id>')

-- audit_trail is 171M rows and the optimizer scans ~2M pages for the date filter. The cover index
-- (source_area_cd, key1_cd, column_changed, date_created) finds the first uid in the 30-day window in ~2K reads;
-- the clustered key (source_area_cd, audit_trail_uid) then lets the main read start there.
-- NOTE: KBJS_audit_trail_Cover01 is a KB/JS-era index - if it is ever dropped, remove the hint (slower, not wrong).
DECLARE @win_start DATETIME = DATEADD(dd, -30, DATEDIFF(dd, 0, GETDATE()))
DECLARE @win_end   DATETIME = DATEDIFF(dd, 0, GETDATE())
DECLARE @min_audit_uid BIGINT = (
	SELECT MIN(audit_trail_uid)
	FROM audit_trail WITH (NOLOCK, INDEX(KBJS_audit_trail_Cover01))
	WHERE source_area_cd = 1319 AND key1_cd = 'order_no' AND column_changed = 'disposition' AND date_created >= @win_start)

-- Materialize the 30-day backorder-disposition audit rows once (~22K rows). Left inline, the optimizer probes
-- audit_trail once per backorder line (3,391 probes = 1.6M reads).
SELECT key1_value, line_no, MAX(date_created) date_created
INTO #bo_audit
FROM audit_trail WITH (NOLOCK)
WHERE source_area_cd = 1319
	AND audit_trail_uid >= @min_audit_uid
	AND key1_cd = 'order_no'
	AND column_changed = 'disposition'
	AND new_value = 'B'
	AND date_created BETWEEN @win_start AND @win_end
GROUP BY key1_value, line_no

SELECT
	loc.buyer
	, ol.order_no
	, ol.line_no
	, ol.source_loc_id loc_id
	, ol.item_id
	, FORMAT(ol.unit_quantity * ol.unit_size - ol.qty_invoiced - ol.qty_canceled
			- ol.qty_allocated / ol.unit_size - ol.qty_on_pick_tickets, 'N2') order_qty_bo
	, FORMAT(loc.qty_bo, 'N2') total_bo
	, CAST(a.date_created AS DATE) bo_date
	, FORMAT(loc.qty_on_hand, 'N2') on_hand
	, FORMAT(ISNULL(loc.qty_po,0), 'N2') po
	, FORMAT(ISNULL(loc.qty_xfer_in,0), 'N2') xfer
	, FORMAT(loc.net_avail, 'N2') net_avail
	, m.base_unit uom
FROM p21_view_oe_line ol
	INNER JOIN p21_view_oe_hdr h
		ON h.order_no = ol.order_no
	INNER JOIN p21_view_inv_mast m
		ON m.inv_mast_uid = ol.inv_mast_uid
	INNER JOIN #bo_audit a
		ON a.key1_value = ol.order_no
			AND a.line_no = ol.line_no
	INNER JOIN p21_view_inv_loc l
		ON l.location_id = ol.source_loc_id
			AND l.inv_mast_uid = ol.inv_mast_uid
	INNER JOIN p21_view_inventory_supplier sup
		ON sup.inv_mast_uid = l.inv_mast_uid
	INNER JOIN p21_view_inventory_supplier_x_loc sl
		ON sl.inventory_supplier_uid = sup.inventory_supplier_uid
			AND sl.location_id = l.location_id
			AND sl.primary_supplier = 'y'
	INNER JOIN p21_view_supplier supplier
		ON supplier.supplier_id = sup.supplier_id
	LEFT JOIN p21_view_contacts c
		ON c.id = supplier.buyer_id
	LEFT JOIN p21_view_inv_loc_stock_status s
		ON s.location_id = l.location_id
			AND s.inv_mast_uid = l.inv_mast_uid
	OUTER APPLY (
				SELECT SUM(pl.qty_ordered - pl.qty_allocated - pl.qty_on_pick_tickets - pl.qty_invoiced - pl.qty_canceled) qty_pending
				FROM p21_view_oe_line pl
					INNER JOIN p21_view_oe_hdr ph ON pl.order_no = ph.order_no
				WHERE pl.source_loc_id = l.location_id
					AND pl.inv_mast_uid = l.inv_mast_uid
					AND (
						(l.stockable = 'n' AND ph.validation_status = 'Hold' AND pl.complete = 'n'
							AND ISNULL(pl.product_group_id,'') NOT IN ('ocharge','samples') AND pl.disposition = 'B')
						OR
						(ph.approved = 'n' AND pl.delete_flag = 'n' AND pl.complete = 'n'
							AND ISNULL(pl.product_group_id,'') NOT IN ('ocharge','samples') AND pl.disposition = 'B')
					)
				) pending
	CROSS APPLY (
				SELECT c.id buyer_id, c.contact_name buyer
					, l.qty_backordered qty_bo, l.qty_on_hand, l.order_quantity qty_po
					, l.qty_in_transit - l.qty_reserved_due_in qty_xfer_in
					, l.qty_on_hand - l.qty_allocated - l.qty_backordered - l.qty_reserved_due_in - ISNULL(s.qty_quarantined,0)
						+ ISNULL(pending.qty_pending,0) + l.qty_in_transit + l.order_quantity net_avail
				) loc
WHERE
	ol.disposition = 'B'
	AND h.completed <> 'Y' AND h.projected_order <> 'Y' AND h.rma_flag <> 'Y'
	AND ol.complete <> 'Y' AND ol.delete_flag <> 'Y' AND ol.cancel_flag <> 'Y'
	AND ol.parent_oe_line_uid = 0
	AND EXISTS (SELECT 1 FROM oe_hdr_salesrep hs WHERE hs.order_number = h.order_no AND hs.primary_salesrep = 'Y')
	AND ISNULL(m.default_product_group,'') NOT IN ('samples', 'ocharge')
	AND loc.net_avail < 0
	AND DATEDIFF(DAY, a.date_created, GETDATE()) > 4
	AND (loc.buyer_id = @buyer_id OR loc.buyer_id IS NULL OR @buyer_id IS NULL)
ORDER BY a.date_created

DROP TABLE #bo_audit
