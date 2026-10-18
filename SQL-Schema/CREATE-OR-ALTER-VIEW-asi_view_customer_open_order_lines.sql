/*
    asi_view_customer_open_order_lines
    Rebuild of Portals/customer_tab_open_order_lines.srd, native P21 only.
    Replaces kb_view_open_orders, kb_view_salesrep, kb_sales_history_report_view.

    WHY A VIEW (not inline DataWindow SQL):
    The .srd's retrieve= SQL is parsed by PowerBuilder to build the DataWindow object.
    Nested CASE / COALESCE / NULLIF inlined directly into the .srd makes PB fail to build
    the element -- a null-reference crash in SelectElement, thrown BEFORE the query ever
    runs (no SQL error surfaced). The original portal worked only because its DataWindow
    SQL was a trivial column list over kb_view_open_orders; keep it that way here too.

    p21_view_GetOpenOrders was considered and rejected (same conclusion reached
    independently on SA-48732's CSR Open Order Team portal, see
    Deploy-Guides/SA-48732-csr-open-order-team-portal.md): it's header-level, 10 columns,
    missing taker/line_no/qty_open/item_id -- can't express one row per line.

    MOSTLY DERIVED FROM A PROVEN SOURCE, NOT GUESSED:
    Portals/SA-48732/asi_view_csr_open_orders.sql solved the near-identical problem for a
    different portal and was proven equivalent to kb_view_open_orders via EXCEPT both
    directions on Prod (6,881/6,881 rows, 0 diff). The open-line filter, qty_open formula,
    and salesrep resolution below are adapted from that proven view rather than guessed.
    Still STILL NOT VERIFIED FOR THIS PORTAL SPECIFICALLY -- SA-48732 proved its own column
    set and its own (stricter) filter choices; this portal keeps some different choices
    (rma_flag left visible instead of excluded -- see note 4). Run the EXCEPT comparison at
    the bottom for THIS view before deploying.

    Deploy to: P21Play (P21Dev.allsurfaces.com) -> P21 (P21.allsurfaces.com). View first,
    then the .srd -- deploying the .srd first gives "Invalid object name" on retrieve.

    FIXED 2026-09-25, first deploy attempt: oe_line has no item_id column (base-table trap,
    see feedback_p21_oe_line_no_item_id in memory) -- now sourced from inv_mast.item_id via
    the existing inv_mast_uid join. Also dropped a dead customer join (joined, never
    referenced in the SELECT).
*/

-- ============================================================================
-- Open questions carried into this rebuild:
--
--  1) RESOLVED 2026-09-25: qty_open now sourced from p21_view_GetOpenOrdersDetail.
--     OpenQuantity -- P21's own official open-quantity view (confirmed via
--     INFORMATION_SCHEMA.COLUMNS: order_no, company_id, line_no, item_id, Description1,
--     OrderQuanity [P21's own typo], UnitName, UnitSize, unit_price, OpenQuantity,
--     OpenValue, customer_id). This replaces the derived
--     (unit_quantity * unit_size) - qty_invoiced - qty_canceled formula borrowed from
--     asi_view_csr_open_orders, which was in base/pricing unit and risked a mismatch
--     against qty_ordered's order unit (see feedback_p21_pricing_unit_vs_order_unit /
--     feedback_p21_pricing_unit_double_conversion). P21's own value sidesteps that.
--     p21_view_GetOpenOrders + GetOpenOrdersDetail were otherwise rejected as the
--     driving source (10 + 12 columns between them, missing taker/job_name/
--     validation_status/approved/rma_flag/disposition/complete/required_date/
--     salesrep/price_family -- still need oe_hdr/oe_line for those), but this one
--     column is worth pulling from them.
--     STILL TO VERIFY: whether every row this view's own filter keeps (oel.complete
--     <> 'Y' etc.) has a matching GetOpenOrdersDetail row. If GetOpenOrdersDetail uses
--     a narrower/different "open" definition, qty_open will come back NULL for some
--     rows -- that's a real signal to chase, not something to silently paper over with
--     a fallback formula. Check the commented query at the bottom after deploying.
--
--  2) kb_sales_history_report_view still has no replacement. Dropped as before -- gp_pct
--     relies only on the invoice_line/order margin CASE, unchanged from the original
--     portal logic (that piece was already p21-native). This is still a scope reduction
--     vs. the original, not a proven equivalent -- flagging again, not re-solved by the
--     SA-48732 precedent (that portal has no gp_pct at all).
--
--  3) contacts/contacts_ud confirmed structurally correct (first_name/last_name + nickname
--     override, id join) via the proven CSR view -- no longer a guess.
--
--  4) CORRECTED 2026-09-25: originally assumed rma_flag should stay unfiltered (visible-
--     but-not-excluded), reasoning the .srd's commented-out "AND rma_flag = 'N'" was a
--     disabled feature. The equivalence check proved that wrong: kb_view_open_orders
--     excludes RMA orders internally (found via a real extra row, order 5307046, a
--     negative-qty return line with rma_flag='Y', present in the rebuild but not the
--     original). The commented line was documenting already-enforced behavior, not an
--     unused option. Filter now matches: oeh.rma_flag = 'N' added to WHERE. rma_flag
--     stays as a visible output column (will always read 'N' now, same as the original
--     effectively always showed, since kb_view_open_orders never let a 'Y' row through).
--     oel-level cancel_flag is still NOT filtered (unlike SA-48732) -- unconfirmed either
--     way; re-run the equivalence check after this fix to see if that's still an open gap.
-- ============================================================================

USE [P21Dev]  --[P21Play]  --[P21] --[P21BusinessRules]  --[P21Training]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[asi_view_customer_open_order_lines]
AS
SELECT
	oeh.order_no,
	oel.line_no,
	oeh.customer_id,
	invoice_no       = COALESCE(invo_line.invoice_no, ''),
	oeh.order_date,
	customer_po_no    = oeh.po_no,
	item_id = im.item_id,  -- oe_line has no item_id (base-table trap); it's on inv_mast via inv_mast_uid
	im.extended_desc,
	oel.qty_ordered,
	-- note 1: P21's own official value, not derived -- see header note 1
	qty_open          = god.OpenQuantity,
	roll_type = CASE ISNULL(oel.full_rolled_item_cd, '')
		WHEN 3563 THEN 'Cut'
		WHEN 3561 THEN 'Roll'
		WHEN 3562 THEN 'Balance'
		ELSE ''
	END,
	oel.unit_price,
	system_calc_unit_price = CASE oel.manual_price_overide
		WHEN 'Y' THEN oel.system_calc_unit_price
		ELSE NULL
	END,
	oel.extended_price,
	-- note 2: gp_pct unchanged from the original portal's own (already p21-native) logic
	gp_pct = CASE
		WHEN invo_line.invoice_no IS NULL THEN
			CASE oel.unit_price
				WHEN 0 THEN NULL
				ELSE (oel.unit_price - oel.commission_cost) / oel.unit_price
			END
		ELSE
			CASE invo_line.price
				WHEN 0 THEN NULL
				ELSE (invo_line.price - invo_line.cost) / invo_line.price
			END
	END,
	oel.disposition,
	oeh.rma_flag,
	oeh.cancel_flag,
	oeh.validation_status,
	oeh.approved,
	oel.complete,
	oel.required_date,
	oeh.taker,
	oeh.job_name,
	-- note 3: salesrep resolution + name, adapted from the proven asi_view_csr_open_orders
	-- (NULLIF guards required -- UD fields store 0, not NULL, when empty)
	salesrep_id   = COALESCE(NULLIF(oelud.updated_salesrep_id, 0), NULLIF(oelud.oe_salesrep_id, 0), ohsr.salesrep_id),
	salesrep_name = CASE WHEN LEN(RTRIM(LTRIM(ISNULL(sr_ud.nickname, '')))) > 0
		THEN sr_ud.nickname ELSE sr.first_name END + ' ' + sr.last_name,
	ship_to_id    = oeh.address_id,
	price_family  = CASE im.default_price_family_uid
		WHEN 3 THEN 'CCS'
		WHEN 2 THEN 'All Tile'
		ELSE ''
	END
FROM oe_hdr AS oeh
	INNER JOIN oe_line AS oel
		ON oel.order_no = oeh.order_no
		AND oel.parent_oe_line_uid = 0
	LEFT JOIN inv_mast AS im
		ON im.inv_mast_uid = oel.inv_mast_uid
	LEFT JOIN oe_line_ud AS oelud
		ON oelud.order_no = oel.order_no
		AND oelud.line_no = oel.line_no
	-- primary_salesrep only: oe_hdr_salesrep carries split commissions and would otherwise
	-- multiply order lines. Do NOT remove this predicate (see SA-48732's split-commission trap).
	LEFT JOIN oe_hdr_salesrep AS ohsr
		ON ohsr.order_number = oeh.order_no
		AND ohsr.primary_salesrep = 'Y'
	-- Salesrep is LINE-level by design (a line can be reassigned off the header rep);
	-- fall back to the header rep only when the line has none of its own.
	LEFT JOIN contacts AS sr
		ON sr.id = COALESCE(
			CONVERT(VARCHAR(16), NULLIF(oelud.updated_salesrep_id, 0)),
			CONVERT(VARCHAR(16), NULLIF(oelud.oe_salesrep_id, 0)),
			ohsr.salesrep_id)
	LEFT JOIN contacts_ud AS sr_ud
		ON sr_ud.id = sr.id
	-- Invoice numbers/pricing -- already p21-native in the original, unchanged here
	LEFT JOIN (
		SELECT
			il.order_no,
			il.oe_line_number,
			MAX(il.invoice_no)           AS invoice_no,
			SUM(il.unit_price_home)      AS price,
			SUM(il.commission_cost_home) AS cost
		FROM p21_view_invoice_line il
		GROUP BY il.order_no, il.oe_line_number
	) AS invo_line
		ON invo_line.order_no        = oel.order_no
		AND invo_line.oe_line_number = oel.line_no
	-- P21's own official open-quantity view -- see header note 1
	LEFT JOIN p21_view_GetOpenOrdersDetail AS god
		ON god.order_no   = oeh.order_no
		AND god.line_no   = oel.line_no
		AND god.company_id = oeh.company_id
WHERE
	oeh.delete_flag         = 'N'
	AND oeh.projected_order = 'N'
	AND oeh.cancel_flag     = 'N'
	AND oeh.rma_flag        = 'N'    -- kb_view_open_orders excludes RMAs; confirmed 2026-09-25
	AND oel.delete_flag     = 'N'
	AND oel.complete        <> 'Y'
	AND oeh.completed        <> 'Y'  -- header-level completion, distinct from oel.complete
GO

GRANT SELECT ON dbo.asi_view_customer_open_order_lines TO p21_application_role;
GRANT SELECT ON dbo.asi_view_customer_open_order_lines TO PxxiUser;
GO

-- ============================================================================
-- Test pass, scoped to the last year per discussion -- validate here first before
-- widening. Compare against the ORIGINAL .srd's retrieve= SQL for the same customer
-- (EXCEPT both directions) rather than eyeballing -- that's what caught the salesrep
-- blank-on-no-oe_line_ud-row bug on SA-48732.
-- ============================================================================
--DECLARE @cust_id INT = 0;  -- set to a real customer_id with open history for testing
--SELECT *
--FROM dbo.asi_view_customer_open_order_lines
--WHERE customer_id = @cust_id
--	AND order_date >= DATEADD(YEAR, -1, GETDATE())
--ORDER BY order_no, line_no;

-- Match-rate check for note 1 -- how many of the rows THIS view's own filter keeps have
-- no matching p21_view_GetOpenOrdersDetail row (qty_open will be NULL for those)?
--SELECT COUNT(*) AS total_rows, SUM(CASE WHEN qty_open IS NULL THEN 1 ELSE 0 END) AS null_qty_open
--FROM dbo.asi_view_customer_open_order_lines;
