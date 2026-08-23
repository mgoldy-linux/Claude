SELECT DISTINCT 'HDRXXXXDET' hdrxxxxdef  
		,' ' title
		,SUBSTRING(oe_hdr.ship2_name, 1, 40) ship2_name
		,' ' format_ship2_addr1
		,' ' format_ship2_addr2
		,' ' format_ship2_addr3
		,' ' format_ship2_addr4
		,oe_hdr.ship2_add1 ship2_address1
		,oe_hdr.ship2_add2 ship2_address2
		,oe_hdr.ship2_city
		,oe_hdr.ship2_state
		,COALESCE(oe_hdr.ship2_zip, '') ship2_zip
		,oe_hdr.ship2_country
		,carrier.name carrier_name
		,COALESCE(scan_pack_container_hdr.tracking_no,CONVERT(CHAR(255),scan_pack_container_hdr.scan_pack_uid)) tracking_no
		,SUBSTRING(address.name, 1, 40) location_name
		,' ' format_loc_addr1
		,' ' format_loc_addr2
		,' ' format_loc_addr3
		,' ' format_loc_addr4
		,' ' format_loc_addr5
		,address.mail_address1 location_address1
		,address.mail_address2 location_address2
		,address.mail_city location_city
		,address.mail_state location_state
		,address.mail_postal_code location_zip
		,address.mail_country location_country
		,address.central_phone_number location_phone
		,oe_hdr.po_no
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN 'VPN#' 
			ELSE NULL
		END vpn_no_text
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN drv_lines.item_id
			ELSE NULL
		END vpn_no
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN 'SKU#' 
			ELSE NULL
		END sku_no_text
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN drv_lines.customer_part_number 
			ELSE NULL
		END sku_no
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN 'QTY:' 
			ELSE NULL
		END qty_text
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN drv_lines.container_qty 
			ELSE NULL
		END qty
		,CASE 
			WHEN (drv_shipcount.shipcount > 1) THEN 'MIXED' 
			ELSE NULL
		END contents_mixed
		,CASE
			WHEN (drv_shipcount.shipcount = 1) THEN 'UPC:' 
			ELSE NULL
		END upc_code_text
		,CASE
			WHEN (drv_shipcount.shipcount = 1) THEN drv_lines.upc_code 
			ELSE NULL
		END upc_code
		,CASE
			WHEN (drv_shipcount.shipcount > 1) THEN 'MIXED' 
			ELSE NULL
		END upc_mixed
		,drv_shipping_package_type.carton_pallet_qty_text
		,'          ' carton_pallet_qty
		,scan_pack_container_hdr.weight weight
		,scan_pack_container_hdr.container_id serial_shipping_container_code
		,CASE 
			WHEN (drv_hazmat.hazmatcount > 0) THEN 'HAZARDOUS MATERIAL ENCLOSED' 
			ELSE NULL
		END hazardous_material_text
		,CONVERT(VARCHAR(20), 5672) header_number
		,oe_hdr.company_id
		,oe_hdr.customer_id
		,oe_hdr.ship2_add3 ship2_address3
		,address.mail_address3 location_address3
		,CASE 
			WHEN (drv_shipcount.shipcount = 1)
			THEN drv_lines.check_digit
			ELSE NULL
		END check_digit	
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN 'EAN:' 
			ELSE NULL
		END ean_code_text
		,CASE 
			WHEN (drv_shipcount.shipcount = 1) THEN drv_lines.ean_code 
			ELSE NULL
		END ean_code		
/*MAIN FROM CLAUSE*/
FROM scan_pack_container_hdr
INNER JOIN	(	SELECT		scan_pack_container_hdr.scan_pack_uid,
									CASE WHEN MIN(shipping_package_type.packaging_type) = MAX(shipping_package_type.packaging_type) THEN
											CASE MIN(shipping_package_type.packaging_type)
												WHEN 'C' THEN 'Carton Quantity:' 
												WHEN 'P' THEN 'Pallet Quantity:' 
												WHEN 'T' THEN 'Truck Quantity:' 
											END
										ELSE 'Package Quantity:'
									END carton_pallet_qty_text 
					FROM			scan_pack_container_hdr
					INNER JOIN	shipping_package_type ON shipping_package_type.shipping_package_type_uid = scan_pack_container_hdr.shipping_package_type_uid
					WHERE		scan_pack_container_hdr.scan_pack_uid =  5672
					GROUP BY	scan_pack_container_hdr.scan_pack_uid
				) drv_shipping_package_type ON (drv_shipping_package_type.scan_pack_uid = scan_pack_container_hdr.scan_pack_uid)
INNER JOIN scan_pack_container_detail ON scan_pack_container_detail.scan_pack_container_hdr_uid = scan_pack_container_hdr.scan_pack_container_hdr_uid
INNER JOIN  (	SELECT		TOP 1 scan_pack_container_detail.pick_ticket_no,
									scan_pack_container_hdr.scan_pack_uid
					FROM			scan_pack_container_detail
					INNER JOIN	scan_pack_container_hdr ON (scan_pack_container_hdr.scan_pack_container_hdr_uid = scan_pack_container_detail.scan_pack_container_hdr_uid)
					WHERE		scan_pack_container_hdr.scan_pack_uid = 5672
							AND	scan_pack_container_detail.row_status_flag = 704
							AND 	scan_pack_container_detail.pick_ticket_no IS NOT NULL
							AND	scan_pack_container_hdr.row_status_flag = 704
					) AS drv_oe_pick_ticket ON (drv_oe_pick_ticket.scan_pack_uid = scan_pack_container_hdr.scan_pack_uid)
INNER JOIN oe_pick_ticket ON oe_pick_ticket.pick_ticket_no = drv_oe_pick_ticket.pick_ticket_no
INNER JOIN oe_hdr ON oe_hdr.order_no = oe_pick_ticket.order_no
INNER JOIN address ON address.id = oe_pick_ticket.location_id
LEFT JOIN address carrier ON carrier.id = scan_pack_container_hdr.carrier_id
LEFT JOIN (	SELECT	COUNT(1) shipcount,
							drv.scan_pack_container_hdr_uid
				FROM	(	SELECT		scan_pack_container_detail.scan_pack_container_hdr_uid
							FROM			scan_pack_container_detail
							INNER JOIN	scan_pack_container_hdr ON (scan_pack_container_hdr.scan_pack_container_hdr_uid = scan_pack_container_detail.scan_pack_container_hdr_uid)
							WHERE		scan_pack_container_detail.row_status_flag = 704
									AND	scan_pack_container_hdr.scan_pack_uid = 5672
							UNION ALL
							SELECT		scan_pack_container_detail.scan_pack_container_hdr_uid
							FROM			scan_pack_container_detail
							INNER JOIN	scan_pack_container_hdr ON (scan_pack_container_hdr.scan_pack_container_hdr_uid = scan_pack_container_detail.scan_pack_container_hdr_uid)
							INNER JOIN	scan_pack_container_hdr scan_pack_container_hdr2 ON (scan_pack_container_hdr2.scan_pack_container_hdr_uid = scan_pack_container_detail.inner_scan_pack_container_hdr_uid)
							WHERE		scan_pack_container_detail.row_status_flag = 704
									AND	scan_pack_container_hdr.scan_pack_uid = 5672
	) AS drv
	GROUP BY	drv.scan_pack_container_hdr_uid
			) AS drv_shipcount ON drv_shipcount.scan_pack_container_hdr_uid = scan_pack_container_hdr.scan_pack_container_hdr_uid			
LEFT JOIN (	SELECT		inv_mast.item_id,i
								oe_line.customer_part_number,
								scan_pack_container_detail.unit_quantity as container_qty,
								inventory_supplier.upc_code,
								scan_pack_container_detail.scan_pack_container_hdr_uid,
								inventory_supplier.check_digit,
								inventory_supplier.ean_code
				FROM			scan_pack_container_detail
				INNER JOIN	scan_pack_container_hdr ON scan_pack_container_hdr.scan_pack_container_hdr_uid = scan_pack_container_detail.scan_pack_container_hdr_uid
				INNER JOIN	oe_pick_ticket ON oe_pick_ticket.pick_ticket_no = scan_pack_container_detail.pick_ticket_no
				INNER JOIN	oe_pick_ticket_detail ON	oe_pick_ticket_detail.pick_ticket_no = scan_pack_container_detail.pick_ticket_no
												AND		oe_pick_ticket_detail.line_number = scan_pack_container_detail.line_number
				INNER JOIN	oe_line ON	oe_line.order_no = oe_pick_ticket.order_no
									AND oe_line.line_no = oe_pick_ticket_detail.oe_line_no
				INNER JOIN	inv_mast ON inv_mast.inv_mast_uid = oe_line.inv_mast_uid
				INNER JOIN	inventory_supplier ON	inventory_supplier.inv_mast_uid = oe_line.inv_mast_uid
												AND inventory_supplier.supplier_id = oe_line.supplier_id
				WHERE		scan_pack_container_detail.row_status_flag = 704
					AND		scan_pack_container_hdr.scan_pack_uid = 5672
			) AS drv_lines ON drv_lines.scan_pack_container_hdr_uid = scan_pack_container_hdr.scan_pack_container_hdr_uid			
LEFT JOIN (	SELECT		COUNT(1) hazmatcount,
								scan_pack_container_detail.scan_pack_container_hdr_uid
				FROM			scan_pack_container_hdr
				INNER JOIN	scan_pack_container_detail ON (scan_pack_container_detail.scan_pack_container_hdr_uid = scan_pack_container_hdr.scan_pack_container_hdr_uid)
				LEFT JOIN	scan_pack_container_hdr scan_pack_container_hdr2 ON (scan_pack_container_hdr2.scan_pack_container_hdr_uid = scan_pack_container_detail.inner_scan_pack_container_hdr_uid)
				LEFT JOIN	scan_pack_container_detail scan_pack_container_detail2 ON (scan_pack_container_detail2.scan_pack_container_hdr_uid = scan_pack_container_hdr2.scan_pack_container_hdr_uid)
				LEFT JOIN	scan_pack_container_hdr scan_pack_container_hdr3 ON (scan_pack_container_hdr3.scan_pack_container_hdr_uid = scan_pack_container_detail2.inner_scan_pack_container_hdr_uid)
				LEFT JOIN	scan_pack_container_detail scan_pack_container_detail3 ON (scan_pack_container_detail3.scan_pack_container_hdr_uid = scan_pack_container_hdr3.scan_pack_container_hdr_uid)
				INNER JOIN	oe_pick_ticket_detail ON oe_pick_ticket_detail.pick_ticket_no = COALESCE(scan_pack_container_detail.pick_ticket_no,scan_pack_container_detail2.pick_ticket_no,scan_pack_container_detail3.pick_ticket_no)
														AND oe_pick_ticket_detail.line_number = COALESCE(scan_pack_container_detail.line_number, scan_pack_container_detail2.line_number, scan_pack_container_detail3.line_number)
				INNER JOIN	inv_mast ON inv_mast.inv_mast_uid = oe_pick_ticket_detail.inv_mast_uid
											AND inv_mast.haz_mat_flag = 'Y'
				WHERE		scan_pack_container_detail.row_status_flag = 704
					AND		scan_pack_container_hdr.scan_pack_uid = 5672
				GROUP BY	scan_pack_container_detail.scan_pack_container_hdr_uid
				) AS drv_hazmat ON drv_hazmat.scan_pack_container_hdr_uid = scan_pack_container_hdr.scan_pack_container_hdr_uid
/*MAIN WHERE CLAUSE*/
WHERE scan_pack_container_hdr.scan_pack_uid = 5672
  AND scan_pack_container_hdr.row_status_flag = 704
/*MAIN GROUP BY CLAUSE*/
/*MAIN HAVING CLAUSE*/
/*MAIN ORDER BY CLAUSE*/
ORDER BY scan_pack_container_hdr.container_id
