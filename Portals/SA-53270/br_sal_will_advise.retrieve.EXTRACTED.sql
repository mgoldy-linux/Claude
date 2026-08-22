----------------------- 
-- Created by Karen Benish
-- July 29, 2016
-- Shows the open will advise orders for the currently logged in order taker
-- 2/4/21: Changed to refer to required date status table instead of hard coded dates
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
	,p21_view_oe_line.commission_cost
	,p21_view_oe_line.pricing_unit
	,(p21_view_oe_line.commission_cost / p21_view_oe_line.pricing_unit_size) * (p21_view_oe_line.qty_ordered - p21_view_oe_line.qty_canceled) AS extended_cost

FROM p21_view_oe_line
LEFT JOIN p21_view_oe_hdr
	ON p21_view_oe_line.order_no = p21_view_oe_hdr.order_no
-- Limit to this users sales location
INNER JOIN (SELECT location_id FROM dbo.kb_fnt_get_user_loc('<user_id>')) AS my_locs 
	ON my_locs.location_id = p21_view_oe_hdr.location_id
LEFT JOIN oe_hdr_ud WITH(NOLOCK)
	ON p21_view_oe_hdr.order_no = oe_hdr_ud.order_no
LEFT JOIN p21_view_customer
	ON p21_view_customer.customer_id = p21_view_oe_hdr.customer_id
INNER JOIN kb_table_required_date_statuses AS rds 
	ON rds.row_status_flag = 704 AND rds.required_date = p21_view_oe_hdr.requested_date

WHERE
	-- Will advise special date 
	rds.order_status = 'Will Advise'
	-- Not complete, deleted or cancelled 
	AND p21_view_oe_line.complete = 'N' AND p21_view_oe_line.delete_flag = 'N' AND p21_view_oe_line.cancel_flag = 'N'
	AND p21_view_oe_hdr.delete_flag = 'N'
	-- Omit other charge items?
	AND p21_view_oe_line.other_charge = 'N'
	-- Omit RMAs and Quotes
	AND p21_view_oe_hdr.rma_flag = 'N' AND p21_view_oe_hdr.projected_order = 'N'
	-- Omit child order lines
	AND p21_view_oe_line.parent_oe_line_uid = '0'


ORDER BY p21_view_oe_hdr.order_date ASC
