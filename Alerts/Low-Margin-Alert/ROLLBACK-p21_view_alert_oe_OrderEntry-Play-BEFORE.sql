


CREATE   VIEW [dbo].[p21_view_alert_oe_OrderEntry]
AS

SELECT	oe_hdr.order_no 'view_key'
		,oe_hdr.date_last_modified 'next_execution_start_date'
		,ISNULL(oe_hdr.company_id, '') 'company_id'
		,ISNULL(oe_hdr.location_id,0) 'sales_location_id'
		,oe_hdr.customer_id 'customer_id'
		,ISNULL(customer.class_1id, '') 'customer_class_1'
		,ISNULL(customer.class_2id, '') 'customer_class_2'
		,ISNULL(customer.class_3id, '') 'customer_class_3'
		,ISNULL(customer.class_4id, '') 'customer_class_4'
		,ISNULL(customer.class_5id, '') 'customer_class_5'
		,ISNULL(oe_hdr.address_id,0) 'ship_to_id'
		,COALESCE(users_taker.name, '') 'taker'
		,ISNULL(oe_hdr.approved, 'N') 'approved'
		,ISNULL(customer.credit_status, '') 'credit_status'
		,ISNULL(oe_hdr.validation_status, '') 'validation_status'
		,ISNULL(customer.salesrep_id, '') 'sales_rep_id'
		,inv_mast.item_id 'item_id'
		,ISNULL(oe_line.disposition, '') 'disposition'
		,oe_hdr.order_no 'order_number'
		,ISNULL(dbo.p21_fn_DatePart(oe_hdr.order_date), '') 'order_date'
		,ISNULL(address_customer.name, '') 'customer_name'
		,ISNULL(oe_hdr.ship2_name, '') 'ship_to_name'
		,ISNULL(oe_hdr.ship_to_phone, '') 'ship_to_phone'
		,ISNULL(address_ship_to.central_fax_number, '') 'ship_to_fax'
		,ISNULL(oe_hdr.po_no, '') 'purchase_order_number'
		,ISNULL(oe_hdr_salesrep.salesrep_id ,'') 'primary_salesrep_id'
		,ISNULL(oe_hdr.contact_id, '') 'contact_id'
		,CASE ISNULL(contacts_salesrep.mi, '')
		 		WHEN '' THEN
					ISNULL(contacts_salesrep.first_name, '')
					+ ' '
					+ ISNULL(contacts_salesrep.last_name, '')
				ELSE
					ISNULL(contacts_salesrep.first_name, '')
					+ ' '
					+ ISNULL(contacts_salesrep.mi, '')
					+ ' '
					+ ISNULL(contacts_salesrep.last_name, '')
		 END 'primary_salesrep_name'
		,ISNULL(oe_hdr.job_name, '') 'job_name'
		,ISNULL(oe_hdr.delivery_instructions, '') 'shipping_instructions'
		,CASE ISNULL(contacts.mi, '')
				WHEN '' THEN
					ISNULL(contacts.first_name, '')
					+ ' '
					+ ISNULL(contacts.last_name, '')
				ELSE
					ISNULL(contacts.first_name, '')
					+ ' '
					+ ISNULL(contacts.mi, '')
					+ ' '
					+ ISNULL(contacts.last_name, '')
		 END 'contact_name'
		,ISNULL(dbo.p21_fn_DatePart(oe_hdr.requested_date), '') 'required_date'

		,ISNULL(inv_mast.item_desc, '') 'item_description'
		,ISNULL(oe_line.extended_desc, '') 'extended_description'
		-- mg fix decimal precision SA 37384
		,CAST(CASE oe_hdr.rma_flag
			WHEN 'Y'
			THEN  ISNULL(-1*(oe_line.unit_quantity), 0)
   			ELSE  ISNULL(oe_line.unit_quantity, 0)
   		END AS DECIMAL(19,3)) 'order_quantity'
		,ISNULL(oe_line.unit_of_measure, '') 'unit_of_measure'
		,CAST(ISNULL(oe_line.unit_price, 0) AS DECIMAL(19,2)) 'unit_price'
		,CAST(CASE oe_hdr.rma_flag
			WHEN 'Y' THEN
				-1*(oe_line.extended_price)
			ELSE
				oe_line.extended_price
		END AS DECIMAL(19, 2)) 'extended_price'
		,ISNULL(dbo.p21_fn_DatePart(oe_line.required_date), '') 'line_required_date'
		,ISNULL(oe_line.supplier_id, 0) 'supplier_id'
		,ISNULL(supplier.supplier_name, '') 'supplier_name'
		,dbo.p21_fn_MaskDecimal((ISNULL(oe_line.qty_allocated, 0) / oe_line.unit_size), 'Qty') 'quantity_allocated'
		,ISNULL(oe_line.manual_price_overide, '') 'price_edit'
		, COALESCE(drv_oe_line.total_line_items, 0) AS total_line_items
		, CAST
			(
					CASE oe_hdr.rma_flag
						WHEN 'Y' THEN drv_oe_line.rma_total_amount
						ELSE drv_oe_line.std_total_amount
					END
				AS
				DECIMAL(19, 2)
			) 'total_amount'
		,oe_hdr.profit_percent AS order_profit_percentage
		,CAST(
				CASE
					WHEN ISNULL (oe_line.extended_price, 0) <= 0 THEN 0
					ELSE(
							(oe_line.unit_price) -
							(
								CASE
									WHEN users.default_costing_basis = 2 THEN oe_line.commission_cost
									WHEN users.default_costing_basis = 3 THEN oe_line.other_cost
									--12.14 MMV 12/20/13 - Feature 55648, Scopus 1185966: Calculate Profit based on the new option of cost basis: carrier rebate cost
									WHEN users.default_costing_basis = 4 THEN oe_line.carrier_rebate_cost
									ELSE oe_line.sales_cost
								 END
							)
						) / oe_line.unit_price * 100
				END AS DECIMAL(19, 2)
			 ) AS 'line_item_profit_percentage'
		,ISNULL(oe_hdr.projected_order, '') 'quote'
		,ISNULL(oe_line.will_call, '') 'will_call'
		,ISNULL(oe_hdr.source_code_no, 0) 'source_type'
		,dbo.p21_fn_validate_email_address(contacts_buyer.email_address) 'buyer_email'
		,dbo.p21_fn_validate_email_address(users.email_address) 'user_email'
		,dbo.p21_fn_validate_email_address(contacts.email_address) 'contact_email'
		,dbo.p21_fn_validate_email_address(address_customer.email_address) 'customer_email'
		,dbo.p21_fn_validate_email_address(oe_hdr.ship2_email_address) 'ship_to_email'
		,dbo.p21_fn_validate_email_address(users_taker.email_address) 'taker_email'
		,dbo.p21_fn_validate_email_address(contacts_salesrep.email_address) 'primary_salesrep_email'
		,ISNULL(oe_hdr.rma_flag, '') 'rma_flag'
		,ISNULL(oe_hdr.web_reference_no, '') 'web_reference_no'
		,ISNULL(oe_hdr.source_code_no, 0) 'source_code_no'
		,CASE
			WHEN oe_line.date_created = oe_line.date_last_modified AND oe_line.date_last_modified >= oe_hdr.date_last_modified
				THEN 'Y'
			WHEN oe_line.date_created <> oe_line.date_last_modified AND oe_line.date_last_modified >= oe_hdr.date_last_modified
				THEN 'N'
			ELSE
			     'X'
			END 'new_trans'

		,ISNULL(oe_line.product_group_id, '') 'product_group_id'

		--Customer Address
		,COALESCE(address_customer.mail_address1, '') 'bill_to_address_1'
		,COALESCE(address_customer.mail_address2, '') 'bill_to_address_2'
		-- JLE 05/02/13 Feature 53685: Add address line 3 information
		,COALESCE(address_customer.mail_address3, '') 'bill_to_address_3'
		,COALESCE(address_customer.mail_city, '') 'bill_to_city'
		,COALESCE(address_customer.mail_state, '') 'bill_to_state'
		,COALESCE(address_customer.mail_postal_code, '') 'bill_to_zip'
		,COALESCE(address_customer.mail_country, '') 'bill_to_country'
		--Ship To Address
		,COALESCE(oe_hdr.ship2_add1, '') 'ship_to_address_1'
		,COALESCE(oe_hdr.ship2_add2, '') 'ship_to_address_2'
		-- JLE 05/02/13 Feature 53685: Add address line 3 information
		,COALESCE(oe_hdr.ship2_add3, '') 'ship_to_address_3'
		,COALESCE(oe_hdr.ship2_city, '') 'ship_to_city'
		,COALESCE(oe_hdr.ship2_state, '') 'ship_to_state'
		,COALESCE(oe_hdr.ship2_zip, '') 'ship_to_zip'
		,COALESCE(oe_hdr.ship2_country, '') 'ship_to_country'
		,COALESCE(oe_line.customer_part_number, '') 'customer_part_number'
		,dbo.p21_fn_MaskDecimal(COALESCE(oe_line.qty_on_pick_tickets, 0), 'Qty') 'quantity_picked'
		,CASE
			WHEN COALESCE(customer.credit_limit,0) > 0 THEN
	  			CASE
			  		WHEN COALESCE(customer.credit_limit_used,0) > COALESCE(customer.credit_limit,0) THEN
		    			'Y'
			  		ELSE
	     	    		'N'
		  		END
	  		ELSE
	   			'N'
		 END 'credit_limit_exceeded'
		,COALESCE(oe_hdr.credit_card_hold, 0) 'credit_card_hold'
		,dbo.p21_fn_MaskDecimal((oe_line.qty_ordered - oe_line.qty_canceled) / oe_line.unit_size, 'Qty') 'fill_quantity'
		,CAST((oe_line.qty_ordered - oe_line.qty_canceled)
				/ oe_line.pricing_unit_size * oe_line.unit_price AS DECIMAL(19, 2)) 'fill_extended_price'
		,CAST(COALESCE(oe_line.sales_tax, 0) AS DECIMAL(19,2)) 'line_tax'
		,CAST(COALESCE(drv_oe_line.estimated_tax, 0) AS DECIMAL(19,2)) AS 'estimated_tax'
		, COALESCE(oe_hdr.class_1id, '') 'order_class1_id'
		, COALESCE(oe_hdr.class_2id, '') 'order_class2_id'
		, COALESCE(oe_hdr.class_3id, '') 'order_class3_id'
		, COALESCE(oe_hdr.class_4id, '') 'order_class4_id'
		, COALESCE(oe_hdr.class_5id, '') 'order_class5_id'
		, COALESCE(inv_mast.class_id1, '') 'inventory_class1_id'
		, COALESCE(inv_mast.class_id2, '') 'inventory_class2_id'
		, COALESCE(inv_mast.class_id3, '') 'inventory_class3_id'
		, COALESCE(inv_mast.class_id4, '') 'inventory_class4_id'
		, COALESCE(inv_mast.class_id5, '') 'inventory_class5_id'
		, CASE ISNULL(customer.source_type_cd, 0)
			WHEN 1596 THEN -- NEW customer on the fly in RMA Entry
			'Y'
			ELSE 'N'
		 END 'customer_on_the_fly'
		, CASE ISNULL(ship_to.source_type_cd, 0)
			WHEN 1380 THEN -- ship to on the fly in RMA Entry
				CASE
					--WHEN ship_to.date_created > oe_hdr.date_created
					WHEN ship_to.date_created > oe_hdr.date_last_modified
						THEN 'Y'
						ELSE 'N'
						END
			ELSE 'N'
		 END 'ship_to_on_the_fly'

		, COALESCE(address_customer.url, '') 'customer_url'
		, COALESCE(address_customer.central_fax_number, '') 'customer_fax_number'
		, COALESCE(address_customer.central_phone_number, '') 'customer_bill_to_phone'
		, CASE ISNULL(customer.source_type_cd, 0)
			WHEN 1595 THEN -- NEW customer on the fly in OE
			'Y'
			ELSE 'N'
		 END 'customer_on_the_fly_in_OE'


		, CASE ISNULL(ship_to.source_type_cd, 0)
			WHEN 1379 THEN -- ship to on the fly in OE
				CASE
					--WHEN ship_to.date_created > oe_hdr.date_created
					WHEN ship_to.date_created > oe_hdr.date_last_modified
						THEN 'Y'
						ELSE 'N'
						END
			ELSE 'N'
		 END 'ship_to_on_the_fly_in_OE'

		, CASE ISNULL(inv_mast.source_type_cd, 0)
			WHEN 1595 THEN -- NEW item on the fly in OE
			'Y'
			ELSE 'N'
		END 'item_on_the_fly_in_OE'
		, COALESCE(oe_line.source_loc_id, 0) 'source_location_id'
		, COALESCE(dbo.p21_fn_DatePart(oe_line.expedite_date), '') 'expedite_date'
		, dbo.p21_fn_MaskDecimal(COALESCE(oe_line.po_cost, 0), 'Money') 'unit_po_cost'
		, dbo.p21_fn_MaskDecimal(COALESCE(oe_line.po_cost/oe_line.pricing_unit_size * oe_line.unit_quantity * oe_line.unit_size, 0), 'Money') 'extended_po_cost'
		, dbo.p21_fn_MaskDecimal(COALESCE(oe_line.other_cost, 0), 'Money') 'unit_other_cost'
		, dbo.p21_fn_MaskDecimal(COALESCE(oe_line.other_cost/oe_line.pricing_unit_size * oe_line.unit_quantity * oe_line.unit_size, 0), 'Money') 'extended_other_cost'
		, COALESCE(job_price_bin.contract_bin_id, '') 'bin_id'
		,CASE
		WHEN (oe_hdr.date_last_modified = oe_hdr.date_created)
			OR (abs(datediff(s,oe_hdr.date_last_modified,oe_hdr.order_date)) < 2) THEN
			'Y'
		ELSE
			'N'
		END 'new_order'
		,CAST(CASE
		WHEN (oe_hdr.rma_flag = 'N' AND (ISNULL (oe_line.extended_price, 0) <= 0)) OR
		    (oe_hdr.rma_flag = 'Y' AND (ISNULL (ABS(oe_line.extended_price), 0) <= 0)) THEN
		0
		ELSE
		( oe_line.extended_price
		 - oe_line.po_cost
		 * oe_line.unit_quantity
		 * oe_line.unit_size
		 / oe_line.pricing_unit_size)
		 / oe_line.extended_price * 100
		END AS DECIMAL(19, 2)) 'po_cost_profit_percentage'

		, oe_line.commission_cost_edited 'commission_cost_edited'
		, oe_line.other_cost_edited 'other_cost_edited'

		, dbo.p21_fn_MaskDecimal(COALESCE(oe_line.sales_cost, 0), 'Money') 'unit_order_cost'
		, dbo.p21_fn_MaskDecimal(COALESCE(oe_line.sales_cost/oe_line.pricing_unit_size * oe_line.unit_quantity * oe_line.unit_size, 0), 'Money') 'extended_order_cost'
		, dbo.p21_fn_MaskDecimal(COALESCE(oe_line.commission_cost, 0), 'Money') 'unit_commission_cost'

		, CASE oe_hdr.rma_flag
		WHEN 'Y' THEN
			dbo.p21_fn_MaskDecimal(COALESCE(oe_line.commission_cost/oe_line.pricing_unit_size * -1*(oe_line.unit_quantity) * oe_line.unit_size, 0), 'Money')
		ELSE
		 dbo.p21_fn_MaskDecimal(COALESCE(oe_line.commission_cost/oe_line.pricing_unit_size * oe_line.unit_quantity * oe_line.unit_size, 0), 'Money')
		END 'extended_commission_cost'

		,CAST(CASE oe_line.extended_price
		WHEN 0 THEN 0
		ELSE
			((oe_line.unit_price - oe_line.sales_cost) / oe_line.unit_price) * 100
		END AS DECIMAL(19, 2)) 'order_cost_profit_percentage'

		,CAST(CASE oe_line.extended_price
		WHEN 0 THEN 0
		ELSE
			((oe_line.unit_price - oe_line.commission_cost) / oe_line.unit_price) * 100
		END AS DECIMAL(19, 2)) 'commission_cost_profit_percentage'

		,CAST(CASE oe_line.extended_price
		WHEN 0 THEN
		0
		ELSE
		((oe_line.unit_price - oe_line.other_cost) / oe_line.unit_price) * 100
		END AS DECIMAL(19, 2)) 'other_cost_profit_percentage'

		,COALESCE(oe_line_quote_info_27.delivery_quote, '') delivery_time

		,CASE
			WHEN oe_hdr.order_type = 1343
			THEN 'Y'
			ELSE 'N'
		END 'consignment_replenishment_order'
		,CASE
			WHEN oe_hdr.order_type = 1344
			THEN 'Y'
			ELSE 'N'
		END 'consignment_usage_order'

		,oe_hdr.last_maintained_by 'last_maintained_by'

		,COALESCE(product_group.product_group_desc,'') 'product_group_desc'
		,COALESCE(address_customer.corp_address_id, 0) corp_address_id
		,oe_line.parent_oe_line_uid
		,oe_line.detail_type
		,ISNULL(oe_hdr.packing_basis, '') 'packing_basis'
		,COALESCE(dbo.p21_fn_DatePart(oe_line_promise_date.promise_date), '') 'current_promise_date'
		,COALESCE(oe_line_promise_date.alert, '') 'current_promise_date_modified'
		,COALESCE(dbo.p21_fn_DatePart(oe_line_promise_date.original_promise_date), '') 'original_promise_date'
		--APS 2/15/10 Scopus 718352
		,oe_line.line_no 'line_no'
		-- 12.12 CAA 04/01/13 - Scopus# 1132387: Added Carrier Code Token.
		,COALESCE(oe_hdr.carrier_id, 0) 'carrier'
		,COALESCE(item_revision.revision_level, '') 'revision'
		,COALESCE(contacts.direct_phone, '') 'contacts_direct_phone'
		,COALESCE(dbo.p21_fn_DatePart(oe_hdr.promise_date), '') 'header_promise_date'
		,COALESCE(sales_market_group.sales_market_group_id, '') 'sales_market_group_id'
		,COALESCE(oe_hdr.cancel_flag, '') 'cancel_flag'
		,COALESCE(users_taker.id, '') 'task_taker'
		-- 12.17 KMC 03/17/2016 - Feature 60789
		,COALESCE(DATEDIFF(d, oe_line_promise_date.promise_date, anticipated_allocation.expected_delivery_date), 0) 'exp_delivery_date_days_after_prom_date'
		,COALESCE(DATEDIFF(d, oe_line_promise_date.promise_date, anticipated_allocation.expected_inbound_date), 0) 'exp_in_stock_date_days_after_prom_date'
		,COALESCE(lost_sales.lost_sales_id, '') 'reason_cd'
		,COALESCE(lost_sales.lost_sales_desc, '') 'reason_cd_desc'
		,COALESCE(restricted_class.class_id, 'NULL') 'restricted_class_id'
		,COALESCE(restricted_class.class_description, '') 'restricted_class_description'
		-- mg add for SA 37384
		, CAST(COALESCE(inv_loc.standard_cost / NULLIF(oe_line.pricing_unit_size, 0) * oe_line.unit_quantity * oe_line.unit_size, 0) AS DECIMAL(19,2)) 'extended_standard_cost'
		-- mg add for reward alert SA 41873
		,CAST(COALESCE(oe_line_ud.extended_reward, 0) AS DECIMAL(19,2)) 'extended_reward'
		,COALESCE(oe_line_ud.reward_program_id, '')                      'reward_program_id'
FROM	pending_alerts
INNER JOIN oe_hdr ON (pending_alerts.trans_no_varchar = oe_hdr.order_no)
INNER JOIN oe_line ON (oe_hdr.order_no = oe_line.order_no)
--12.14 YCHEN 12/16/13 - Feature 56120: Exclude subtotal item (product_type = 'B') show up on OE alert notification.
--INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = oe_line.inv_mast_uid)
INNER JOIN inv_mast ON (inv_mast.inv_mast_uid = oe_line.inv_mast_uid)
				   AND (inv_mast.product_type <> 'B')
INNER JOIN customer ON (customer.customer_id = oe_hdr.customer_id)
				   AND (customer.company_id = oe_hdr.company_id)
INNER JOIN supplier ON (oe_line.supplier_id = supplier.supplier_id)
INNER JOIN inv_loc ON (inv_loc.inv_mast_uid = inv_mast.inv_mast_uid)
	AND (inv_loc.location_id = oe_line.source_loc_id)
INNER JOIN oe_hdr_salesrep ON (oe_hdr_salesrep.order_number = oe_hdr.order_no)
				  AND (oe_hdr_salesrep.primary_salesrep = 'Y')
LEFT JOIN contacts AS contacts_buyer ON (supplier.buyer_id = contacts_buyer.id)
				AND (contacts_buyer.buyer = 'Y')
LEFT JOIN users AS users_taker ON (users_taker.id = oe_hdr.taker)
INNER JOIN address AS address_customer ON (address_customer.id = oe_hdr.customer_id)
INNER JOIN address AS address_ship_to ON (address_ship_to.id = oe_hdr.address_id)
LEFT JOIN contacts AS contacts_salesrep ON (oe_hdr_salesrep.salesrep_id = contacts_salesrep.id)
LEFT JOIN contacts ON (oe_hdr.contact_id = contacts.id)
INNER JOIN users ON (oe_hdr.last_maintained_by = users.id)
INNER JOIN ship_to ON (ship_to.ship_to_id = oe_hdr.address_id)
				AND (ship_to.company_id = oe_hdr.company_id)
LEFT JOIN job_price_batch_line ON (oe_line.oe_line_uid = job_price_batch_line.oe_line_uid)
LEFT JOIN job_price_bin ON (job_price_batch_line.job_price_bin_uid = job_price_bin.job_price_bin_uid)

LEFT JOIN
(
	SELECT
		oe_line.order_no
		, count(*) AS total_line_items
-- 01/28/09 Scopus 559628: Replace ABS with -1* in RMA entry alert where needed
		, SUM(ROUND(((oe_line.unit_price) * (-1*(oe_line.qty_ordered) - oe_line.qty_canceled)) / oe_line.pricing_unit_size, 2)) AS rma_total_amount

		, SUM(ROUND((oe_line.unit_price * (oe_line.qty_ordered - oe_line.qty_canceled)) / oe_line.pricing_unit_size, 2)) AS std_total_amount
		, COALESCE(SUM(
			oe_line.extended_price
			- oe_line.sales_cost
			* oe_line.unit_quantity
			* oe_line.unit_size
			/ oe_line.pricing_unit_size
		)
		/ NULLIF(SUM(oe_line.extended_price),0) * 100, 0) AS order_profit_percentage
		, SUM(oe_line.extended_price) AS extended_price
		, SUM(oe_line.sales_tax) AS estimated_tax
	FROM
		oe_line
		INNER JOIN inv_mast on oe_line.inv_mast_uid = inv_mast.inv_mast_uid AND inv_mast.product_type <> 'B'
	WHERE 	parent_oe_line_uid = 0
	  AND	oe_line.delete_flag <> 'Y'
	GROUP BY
		oe_line.order_no
) AS drv_oe_line
	ON oe_hdr.order_no = drv_oe_line.order_no


LEFT JOIN oe_line_quote_info_27 ON (oe_line_quote_info_27.order_no = oe_line.order_no
	AND oe_line_quote_info_27.line_no = oe_line.line_no
	AND oe_line_quote_info_27.delete_flag = 'N')

-- NJG - F36514
LEFT JOIN product_group ON product_group.company_id = oe_hdr.company_id
				AND product_group.product_group_id = oe_line.product_group_id

-- Riv ZFG 12/04/09 - Scopus 831555
LEFT JOIN	oe_line_promise_date ON oe_line.oe_line_uid = oe_line_promise_date.oe_line_uid
LEFT JOIN revision_transaction ON oe_line.order_no = revision_transaction.transaction_no AND oe_line.line_no = revision_transaction.transaction_line_no
				AND revision_transaction.transaction_code_no = 1533
LEFT JOIN item_revision ON revision_transaction.item_revision_uid = item_revision.item_revision_uid
LEFT JOIN sales_market_group ON oe_hdr.sales_market_group_uid = sales_market_group.sales_market_group_uid
-- 12.17 KMC 03/17/2016 - Feature 60789
LEFT JOIN p21_view_oe_line_anticipated_allocation_summary AS anticipated_allocation ON anticipated_allocation.order_no = oe_line.order_no
     AND anticipated_allocation.line_no = oe_line.line_no
LEFT JOIN lost_sales_transaction ON oe_hdr.order_no = lost_sales_transaction.transaction_no AND lost_sales_transaction.transaction_code_no = 2145
LEFT JOIN lost_sales ON lost_sales_transaction.lost_sales_uid = lost_sales.lost_sales_uid
LEFT JOIN restricted_class ON restricted_class.restricted_class_uid = oe_line.restricted_class_uid
-- mg add for reward alert SA 41873
LEFT JOIN oe_line_ud ON oe_line_ud.order_no = oe_line.order_no AND oe_line_ud.line_no = oe_line.line_no
WHERE	pending_alerts.trans_type_cd IN (1118, 1119, 1120, 1437)
  AND	pending_alerts.marked_for_processing_flag = 'Y'
  AND	oe_hdr.delete_flag = 'N'
  AND	oe_line.delete_flag = 'N'
  AND	oe_hdr.completed <> 'T'


