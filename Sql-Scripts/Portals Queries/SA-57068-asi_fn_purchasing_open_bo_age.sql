-- SA 57068: Purchasing Open BO Age portal as a multi-statement table-valued function.
-- The .srd retrieve= then becomes one line:
--     SELECT * FROM dbo.asi_fn_purchasing_open_bo_age('<user_id>') ORDER BY bo_date
-- (kept as a function so the DataWindow painter never sees the multi-statement SQL -- see SA-55014 guide)
-- Logic = SA-57068-BO-Age-REWRITTEN.sql (proven EXCEPT-equivalent to the original portal query).
-- Multi-statement (not inline) on purpose: the 30-day audit_trail rows must be materialized ONCE in @a.
-- Inline, the optimizer probed audit_trail once per backorder line (3,391 probes, 1.6M reads).
-- v2 (10/15/2026): no index hint. The first audit_trail_uid of the 30-day window is found with a ~28-step binary search on
-- the clustered key (source_area_cd, audit_trail_uid), ~60 reads. Replaces INDEX(KBJS_audit_trail_Cover01) so that
-- KB/JS-era index can be retired. uid rises with date_created, but only approximately, so the search starts 1 day early.
CREATE OR ALTER FUNCTION dbo.asi_fn_purchasing_open_bo_age (@user_id VARCHAR(30))
RETURNS @r TABLE (
	buyer       VARCHAR(44)
	, order_no  VARCHAR(8)
	, line_no   DECIMAL(9,0)
	, loc_id    DECIMAL(9,0)
	, item_id   VARCHAR(40)
	, order_qty_bo NVARCHAR(4000)
	, total_bo  NVARCHAR(4000)
	, bo_date   DATE
	, on_hand   NVARCHAR(4000)
	, po        NVARCHAR(4000)
	, xfer      NVARCHAR(4000)
	, net_avail NVARCHAR(4000)
	, uom       VARCHAR(8)
)
AS
BEGIN
	DECLARE @buyer_id VARCHAR(7) = (SELECT ISNULL(contact_id, '%') FROM p21_view_users WHERE id = @user_id)
	DECLARE @win_start DATETIME = DATEADD(dd, -30, DATEDIFF(dd, 0, GETDATE()))
	DECLARE @win_end   DATETIME = DATEDIFF(dd, 0, GETDATE())
	-- first uid at or after (window start - 1 day); the main read still filters on date_created, so the margin is harmless
	DECLARE @target DATETIME = DATEADD(dd, -1, @win_start)
	DECLARE @lo BIGINT = (SELECT MIN(audit_trail_uid) FROM audit_trail WITH (NOLOCK) WHERE source_area_cd = 1319)
	DECLARE @hi BIGINT = (SELECT MAX(audit_trail_uid) FROM audit_trail WITH (NOLOCK) WHERE source_area_cd = 1319)
	DECLARE @mid BIGINT, @probe_uid BIGINT, @probe_dt DATETIME
	WHILE @lo < @hi
	BEGIN
		SET @mid = (@lo + @hi) / 2
		SELECT TOP 1 @probe_uid = audit_trail_uid, @probe_dt = date_created
		FROM audit_trail WITH (NOLOCK)
		WHERE source_area_cd = 1319 AND audit_trail_uid >= @mid
		ORDER BY audit_trail_uid
		IF @probe_dt < @target SET @lo = @probe_uid + 1 ELSE SET @hi = @mid
	END
	DECLARE @min_audit_uid BIGINT = @lo

	DECLARE @a TABLE (key1_value VARCHAR(255), line_no INT, date_created DATETIME, PRIMARY KEY (key1_value, line_no))
	INSERT INTO @a (key1_value, line_no, date_created)
	SELECT key1_value, line_no, MAX(date_created)
	FROM audit_trail WITH (NOLOCK)
	WHERE source_area_cd = 1319
		AND audit_trail_uid >= @min_audit_uid
		AND key1_cd = 'order_no'
		AND column_changed = 'disposition'
		AND new_value = 'B'
		AND date_created BETWEEN @win_start AND @win_end
	GROUP BY key1_value, line_no

	INSERT INTO @r
	SELECT
		loc.buyer
		, ol.order_no
		, ol.line_no
		, ol.source_loc_id
		, ol.item_id
		, FORMAT(ol.unit_quantity * ol.unit_size - ol.qty_invoiced - ol.qty_canceled
				- ol.qty_allocated / ol.unit_size - ol.qty_on_pick_tickets, 'N2')
		, FORMAT(loc.qty_bo, 'N2')
		, CAST(a.date_created AS DATE)
		, FORMAT(loc.qty_on_hand, 'N2')
		, FORMAT(ISNULL(loc.qty_po,0), 'N2')
		, FORMAT(ISNULL(loc.qty_xfer_in,0), 'N2')
		, FORMAT(loc.net_avail, 'N2')
		, m.base_unit
	FROM p21_view_oe_line ol
		INNER JOIN p21_view_oe_hdr h
			ON h.order_no = ol.order_no
		INNER JOIN p21_view_inv_mast m
			ON m.inv_mast_uid = ol.inv_mast_uid
		INNER JOIN @a a
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

	RETURN
END
GO

-- New objects do not inherit P21 grants (see feedback_p21_new_object_execute_grant). Same two grantees as the
-- other asi_fn_ table-valued functions in Prod (asi_fn_pricing_convert_itvf, asi_fn_packaging_convert_itvf).
-- Without these the portal fails with a permissions error even though the function exists. Safe to re-run.
GRANT SELECT ON dbo.asi_fn_purchasing_open_bo_age TO p21_application_role
GRANT SELECT ON dbo.asi_fn_purchasing_open_bo_age TO PxxiUser
GO
