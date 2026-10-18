----------------------- 
-- Created by Karen Banaszak
-- February 8, 2016
-- Orders placed by date, product, and/or customer
-- 2026-10-16 asi: rep name and sales manager lookup now come from asi_view_salesrep_division_manager
----------------------- 
 SELECT 
	p21_view_oe_hdr.order_no,
	p21_view_oe_line.line_no,
	COALESCE(invo_line.invoice_no, '') AS invoice_no,
	p21_view_oe_hdr.order_date,
	p21_view_customer.customer_id,
	p21_view_customer.customer_name,
	p21_view_oe_hdr.po_no AS customer_po_no,
	p21_view_oe_line.item_id,
	p21_view_inv_mast.extended_desc,
	p21_view_oe_line.qty_ordered,
	CASE ISNULL(p21_view_oe_line.full_rolled_item_cd,0)
		WHEN 3563 THEN 'Cut'
		WHEN 3561 THEN 'Roll'
		WHEN 3562 THEN 'Balance'
		ELSE ''
	END AS roll_type,
	p21_view_oe_line.unit_price,
	CASE manual_price_overide
		WHEN 'Y' THEN p21_view_oe_line.system_calc_unit_price
		ELSE NULL
	END AS system_calc_unit_price,
	p21_view_oe_line.extended_price,
	/*
	HAD TO REMOVE BECAUSE IT MADE THE PORTAL FAR TOO SLOW
		-- check for invoice margin 
		CASE WHEN invo_line.invoice_no IS NULL THEN 
			-- Use order margin
			CASE p21_view_oe_line.unit_price WHEN 0 THEN NULL ELSE (p21_view_oe_line.unit_price-p21_view_oe_line.commission_cost)/p21_view_oe_line.unit_price END 
		ELSE 
			-- Use invoice margin
			CASE WHEN mgn_invo_line.sales_price_home IS NULL 
				THEN CASE invo_line.price WHEN 0 THEN NULL ELSE ((invo_line.price - invo_line.cost)/invo_line.price) END
				ELSE CASE mgn_invo_line.sales_price_home WHEN 0 THEN NULL ELSE (mgn_invo_line.gross_profit_dollars/mgn_invo_line.sales_price_home) END
			END
		END AS gp_pct,
	*/
	p21_view_oe_line.disposition,
	p21_view_oe_hdr.cancel_flag,
	p21_view_oe_hdr.validation_status,
	p21_view_oe_hdr.approved,
	p21_view_oe_line.complete,
	p21_view_oe_line.required_date,
	p21_view_oe_hdr.taker,
	p21_view_oe_hdr.job_name,
	COALESCE(oe_line_ud.updated_salesrep_id, oe_line_ud.oe_salesrep_id) AS salesrep_id,
	rep.salesrep_name,
	p21_view_oe_hdr.address_id AS ship_to_id

FROM 
	p21_view_oe_hdr
	INNER JOIN p21_view_customer 
		ON p21_view_oe_hdr.company_id = p21_view_customer.company_id
		AND p21_view_oe_hdr.customer_id = p21_view_customer.customer_id
	INNER JOIN p21_view_oe_line 
		ON (p21_view_oe_line.order_no = p21_view_oe_hdr.order_no) 
		AND (p21_view_oe_line.parent_oe_line_uid = 0)
	LEFT JOIN oe_line_ud WITH(NOLOCK)
		ON oe_line_ud.order_no = p21_view_oe_hdr.order_no
		AND oe_line_ud.line_no = p21_view_oe_line.line_no
	-- For invoice numbers
	LEFT JOIN (
		SELECT
			p21_view_invoice_line.order_no,
			p21_view_invoice_line.oe_line_number,
			MAX(p21_view_invoice_line.invoice_no) AS invoice_no,
			SUM(unit_price_home) AS price,
			SUM(commission_cost_home) AS cost
		FROM p21_view_invoice_line
		GROUP BY 
			p21_view_invoice_line.order_no, p21_view_invoice_line.oe_line_number
		) AS invo_line
		ON invo_line.order_no = p21_view_oe_line.order_no
		AND invo_line.oe_line_number = p21_view_oe_line.line_no
		AND p21_view_oe_line.parent_oe_line_uid = 0
	LEFT JOIN p21_view_inv_mast
		ON p21_view_inv_mast.inv_mast_uid = p21_view_oe_line.inv_mast_uid
	LEFT JOIN item_commission_class_ud iccu
		ON iccu.commission_class_id = p21_view_inv_mast.commission_class_id
	LEFT JOIN asi_view_salesrep_division_manager rep
		ON rep.salesrep_id = COALESCE(oe_line_ud.updated_salesrep_id, oe_line_ud.oe_salesrep_id)
		AND rep.division = ''
	LEFT JOIN asi_view_salesrep_division_manager sm
		ON sm.salesrep_id = oe_line_ud.updated_salesrep_id
		AND sm.division = COALESCE(iccu.division, '')

WHERE 
	p21_view_oe_hdr.delete_flag = 'N'
	AND p21_view_oe_hdr.projected_order = 'N'
	AND p21_view_oe_line.delete_flag = 'N'
	-- Order was created more than an hour ago
	AND p21_view_oe_hdr.date_created < DateAdd(Hour, -1, GetDate())
	-- Order was in the last year if no other date limitations are given
	AND (p21_view_oe_hdr.order_date > DateAdd(Year, -1, GetDate()) OR :ordered_after_date IS NOT NULL OR :order_date IS NOT NULL)

	AND (:cust_id IS NULL OR p21_view_oe_hdr.customer_id = :cust_id)
	AND (:manufacturer IS NULL OR p21_view_inv_mast.class_id1 = :manufacturer)
	AND (:item_id IS NULL OR p21_view_oe_line.item_id = :item_id) 
	AND (:order_date IS NULL OR CAST(p21_view_oe_hdr.order_date AS DATE) = :order_date)
	AND (:ordered_after_date IS NULL OR p21_view_oe_hdr.order_date > :ordered_after_date)
	AND (:order_taker IS NULL OR p21_view_oe_hdr.taker = :order_taker)
	AND (:job_name IS NULL OR p21_view_oe_hdr.job_name = :job_name)
	AND (:salesrep_id IS NULL OR oe_line_ud.updated_salesrep_id = :salesrep_id)
	AND (:sales_manager_id IS NULL OR sm.sales_manager_id = :sales_manager_id)
	AND (:customer_po IS NULL OR p21_view_oe_hdr.po_no LIKE ('%' + :customer_po + '%'))
	AND (:family IS NULL OR CASE SUBSTRING(RTRIM(:family),1,1) WHEN 'A' THEN 2 WHEN 'C' THEN 3 ELSE NULL END = p21_view_inv_mast.default_price_family_uid)


