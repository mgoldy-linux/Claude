SELECT        dbo.oe_pick_ticket.pick_ticket_no, dbo.oe_hdr.shipping_route_uid AS Route, dbo.oe_pick_ticket.print_date, dbo.oe_hdr.requested_date, COALESCE (dbo.p21_view_clippership_return_10004.carrier_name, dbo.address.name) 
                         AS c_carrier, COALESCE (dbo.oe_pick_ticket.tracking_no, dbo.p21_view_clippership_return_10004.tracking_no, ptshipment.shipment_id) AS c_tracking_no, COALESCE (dbo.p21_view_clippership_return_10004.total_charge, 
                         dbo.oe_pick_ticket.freight_out, 0.00) AS c_freight_out, COALESCE (dbo.oe_pick_ticket.freight_in, 0.00) AS freight_in, dbo.oe_pick_ticket.pick_and_hold, COALESCE (dbo.p21_view_clippership_return_10004.shipped_date, 
                         dbo.oe_pick_ticket.ship_date) AS c_ship_date, dbo.oe_pick_ticket.invoice_no, dbo.oe_pick_ticket.auxiliary, dbo.oe_pick_ticket.direct_shipment, dbo.oe_pick_ticket.delete_flag, dbo.oe_pick_ticket.order_no, 
                         dbo.oe_pick_ticket.total_tax, dbo.freight_code.freight_cd, dbo.oe_pick_ticket.freight_code_uid, dbo.oe_hdr.packing_basis, dbo.oe_hdr.company_id, dbo.oe_pick_ticket.oe_pick_ticket_type_cd, 
                         dbo.oe_pick_ticket.outgoing_freight_cost, 
                         CASE WHEN oe_pick_ticket_type_cd = 1921 THEN 'Parts Pick Ticket' WHEN oe_pick_ticket_type_cd = 1922 THEN 'Service Pick Ticket' WHEN oe_pick_ticket.direct_shipment = 'Y' THEN 'Direct Shipment' WHEN oe_pick_ticket.auxiliary
                          = 'Y' THEN 'Auxiliary Pick Ticket' WHEN oe_pick_ticket.pick_and_hold = 'Y' THEN CASE WHEN oe_hdr.packing_basis = 'Tag and Hold' THEN 'Tag And Hold' ELSE 'Pick And Hold' END ELSE CASE ptshipment.transaction_type_cd
                          WHEN 222 THEN 'Shipped via Order Entry' ELSE 'Regular Pick Ticket' END END + CASE WHEN COALESCE (p21_view_clippership_return_10004.clippership_return_uid, 0) 
                         <> 0 THEN CASE system_setting.value WHEN 'Y' THEN ' (Manifest)' ELSE ' (Clippership)' END WHEN COALESCE (ptshipment.shipment_uid, 0) 
                         <> 0 THEN ' (' + carriertype.code_description + ')' ELSE '' END AS shipment_type_display, CASE ptshipment.transaction_type_cd WHEN 222 THEN oe_hdr.order_no ELSE oe_pick_ticket.pick_ticket_no END AS transaction_no, 
                         ptshipment.shipment_uid, dbo.p21_view_clippership_return_10004.clippership_return_uid, dbo.address.carrier_type_cd, COALESCE (ptshipment.ship_location_id, dbo.oe_pick_ticket.location_id) AS loc, 
                         ptshipment.transaction_type_cd, 0 AS strategic_freight_out, dbo.oe_pick_ticket.carrier_id, dbo.company_strategic_pricing.retail_warehouse_separate_flag, dbo.oe_hdr.front_counter AS front_counter_order, 
                         dbo.location.strategic_retail_location_flag, dbo.oe_hdr.customer_id, CASE invoice_hdr.record_type_cd WHEN 2594 THEN invoice_hdr.record_type_reference_no ELSE '' END AS invoice_Rcd_type, 
                         COALESCE (drv_lot_bill_packing_basis.protect_packing_basis, 'N') AS protect_packing_basis, ups_shipping_route.route_description, dbo.oe_pick_ticket_ups.shipping_route_stop, 
                         driver.first_name + ' ' + driver.last_name AS driver_name, CASE WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'N' THEN 'N' WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'Y' AND 
                         oe_pick_ticket_ups.shipping_route_uid IS NULL THEN 'Y' WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'Y' AND oe_pick_ticket_ups.shipping_route_uid IS NOT NULL 
                         THEN 'R' WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'P' THEN 'P' ELSE 'N' END AS roadnet_status, dbo.freight_code.freight_desc, dbo.oe_hdr.ship2_name, dbo.oe_hdr.ship2_state AS Ship_2_State, 
                         dbo.oe_hdr.order_date, dbo.oe_hdr.location_id, dbo.oe_hdr.taker, dbo.oe_hdr.third_party_billing_flag, dbo.oe_hdr.approved, dbo.oe_hdr.delete_flag AS Expr1, dbo.oe_hdr.projected_order, dbo.oe_hdr.cancel_flag, 
                         ptshipment.shipment_desc, ptshipment.shipment_id, dbo.oe_pick_ticket.instructions
FROM            dbo.oe_pick_ticket INNER JOIN
                         dbo.oe_hdr ON dbo.oe_hdr.order_no = dbo.oe_pick_ticket.order_no LEFT OUTER JOIN
                         dbo.p21_view_clippership_return_10004 ON dbo.p21_view_clippership_return_10004.pick_ticket_no = dbo.oe_pick_ticket.pick_ticket_no AND dbo.p21_view_clippership_return_10004.delete_flag = 'N' LEFT OUTER JOIN
                         dbo.freight_code ON dbo.freight_code.freight_code_uid = dbo.oe_pick_ticket.freight_code_uid LEFT OUTER JOIN
                         dbo.shipment AS ptshipment ON ptshipment.row_status_flag = 2175 AND ptshipment.transaction_type_cd = 1000 AND ptshipment.transaction_no = dbo.oe_pick_ticket.pick_ticket_no LEFT OUTER JOIN
                         dbo.address ON dbo.address.id = COALESCE (ptshipment.carrier_id, dbo.oe_pick_ticket.carrier_id) LEFT OUTER JOIN
                         dbo.code_p21 AS carriertype ON carriertype.code_no = dbo.address.carrier_type_cd LEFT OUTER JOIN
                         dbo.company_strategic_pricing ON dbo.company_strategic_pricing.company_id = dbo.oe_pick_ticket.company_id LEFT OUTER JOIN
                         dbo.location ON dbo.location.location_id = dbo.oe_hdr.location_id AND dbo.location.company_id = dbo.oe_pick_ticket.company_id LEFT OUTER JOIN
                         dbo.invoice_hdr ON dbo.invoice_hdr.invoice_no = CAST(dbo.oe_pick_ticket.invoice_no AS varchar(10)) LEFT OUTER JOIN
                             (SELECT DISTINCT oe_pick_ticket_1.pick_ticket_no, 'Y' AS protect_packing_basis
                               FROM            dbo.oe_pick_ticket AS oe_pick_ticket_1 INNER JOIN
                                                         dbo.oe_pick_ticket_detail ON oe_pick_ticket_1.pick_ticket_no = dbo.oe_pick_ticket_detail.pick_ticket_no INNER JOIN
                                                         dbo.oe_line ON dbo.oe_line.line_no = dbo.oe_pick_ticket_detail.oe_line_no AND dbo.oe_line.order_no = oe_pick_ticket_1.order_no AND dbo.oe_line.detail_type <> 3 LEFT OUTER JOIN
                                                         dbo.oe_line_lot_billing ON dbo.oe_line.oe_line_uid = dbo.oe_line_lot_billing.oe_line_uid
                               WHERE        (dbo.oe_line_lot_billing.oe_line_uid IS NULL) AND (dbo.oe_line_lot_billing.price_basis IS NULL OR
                                                         dbo.oe_line_lot_billing.price_basis <> 'N') OR
                                                         (dbo.oe_line_lot_billing.price_basis IS NULL OR
                                                         dbo.oe_line_lot_billing.price_basis <> 'N') AND (dbo.oe_line_lot_billing.packing_basis IS NULL)) AS drv_lot_bill_packing_basis ON 
                         drv_lot_bill_packing_basis.pick_ticket_no = dbo.oe_pick_ticket.pick_ticket_no LEFT OUTER JOIN
                         dbo.oe_pick_ticket_ups ON dbo.oe_pick_ticket_ups.pick_ticket_no = dbo.oe_pick_ticket.pick_ticket_no LEFT OUTER JOIN
                         dbo.shipping_route AS ups_shipping_route ON ups_shipping_route.shipping_route_uid = dbo.oe_pick_ticket_ups.shipping_route_uid LEFT OUTER JOIN
                         dbo.contacts AS driver ON driver.id = dbo.oe_pick_ticket_ups.driver_id INNER JOIN
                         dbo.system_setting ON dbo.system_setting.name = 'epicor_manifest_enabled'
WHERE        (NOT (dbo.oe_pick_ticket.delete_flag = 'Y')) AND (NOT (dbo.oe_pick_ticket.auxiliary = 'Y')) OR
                         (NOT (dbo.oe_pick_ticket.pick_and_hold = 'Y'))