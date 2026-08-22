-----------------------
-- BR Will Call Orders portal -- SA 53270
-- Built 2026-08-22, mgoldyn, for John's Will Call order cleanup
-- Open orders where Carrier = Will Call, restricted to the user's assigned branch(es)
-- Adapted from BR SAL WILL ADVISE (orig. Karen Benish, 2016) -- kept the proven open-order /
-- branch-restriction logic, swapped the Will-Advise required-date filter for a Carrier = Will
-- Call filter, dropped Cost/Extended Cost, added Promise Date, ORDER BY flipped to DESC.
-----------------------

SELECT
	p21_view_oe_hdr.taker
	,p21_view_oe_hdr.customer_id
	,p21_view_customer.customer_name
	,COALESCE(oe_hdr_ud.order_contact,'') AS order_contact
	,p21_view_oe_hdr.ship_to_phone
	,p21_view_oe_hdr.order_no
	,p21_view_oe_line.item_id
	,p21_view_oe_line.extended_desc
	,p21_view_oe_line.unit_price_home
	,p21_view_oe_line.pricing_unit
	,p21_view_oe_line.qty_ordered
	,p21_view_oe_line.extended_price_home
	,p21_view_oe_hdr.order_date
	,p21_view_oe_hdr.job_name
	,CASE WHEN p21_view_oe_line.date_last_modified > p21_view_oe_hdr.date_last_modified THEN p21_view_oe_line.date_last_modified ELSE p21_view_oe_hdr.date_last_modified END AS date_last_modified
	,p21_view_oe_hdr.promise_date

FROM p21_view_oe_line
LEFT JOIN p21_view_oe_hdr
	ON p21_view_oe_line.order_no = p21_view_oe_hdr.order_no
-- Limit to this user's assigned branch(es) -- asi_fnt_get_user_loc (2026-04-14 rebuild of
-- kb_fnt_get_user_loc, no kb_ dependencies), already live in Play and Prod
INNER JOIN (SELECT location_id FROM dbo.asi_fnt_get_user_loc('<user_id>')) AS my_locs
	ON my_locs.location_id = p21_view_oe_hdr.location_id
LEFT JOIN oe_hdr_ud WITH(NOLOCK)
	ON p21_view_oe_hdr.order_no = oe_hdr_ud.order_no
LEFT JOIN p21_view_customer
	ON p21_view_customer.customer_id = p21_view_oe_hdr.customer_id

WHERE
	-- Not complete, deleted or cancelled
	p21_view_oe_line.complete = 'N' AND p21_view_oe_line.delete_flag = 'N' AND p21_view_oe_line.cancel_flag = 'N'
	AND p21_view_oe_hdr.delete_flag = 'N'
	-- Carrier = Will Call. p21_view_address.id 10002, confirmed identical in Play and Prod via
	-- bi_view_carrier ([Carrier ID]/[Carrier Name]) -- re-verify if this ever moves to a new env.
	-- Hardcoded as a plain WHERE equality (not a JOIN to p21_view_address) to keep this
	-- DataWindow's retrieve SQL as simple as possible; a portal .srd's retrieve= SQL is parsed
	-- by PowerBuilder to BUILD the DataWindow object before any query runs, and extra joins/
	-- multi-condition ON clauses beyond what the source portal already proved out are exactly
	-- what has broken that parse before (SelectElement crash, no SQL error surfaced).
	AND p21_view_oe_hdr.carrier_id = 10002
	-- Omit other charge items?
	AND p21_view_oe_line.other_charge = 'N'
	-- Omit RMAs and Quotes
	AND p21_view_oe_hdr.rma_flag = 'N' AND p21_view_oe_hdr.projected_order = 'N'
	-- Omit child order lines
	AND p21_view_oe_line.parent_oe_line_uid = '0'

ORDER BY p21_view_oe_hdr.order_date DESC
