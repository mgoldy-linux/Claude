--Shipments Tab on Order Entry: 1538243 (GRAINGER CORPORATE BILLING (DC)) Quote: N*
SELECT
   oe_pick_ticket.pick_ticket_no,
   oe_pick_ticket.print_date,
   COALESCE(
      p21_view_clippership_return_10004.carrier_name,
      address.name
   ) c_carrier,
   COALESCE(
      p21_view_clippership_return_10004.tracking_no,
      ptshipment.shipment_id,
      oe_pick_ticket.tracking_no
   ) c_tracking_no,
   COALESCE(
      p21_view_clippership_return_10004.total_charge,
      oe_pick_ticket.freight_out,
      0.00
   ) c_freight_out,
   COALESCE(oe_pick_ticket.freight_in, 0.00) freight_in,
   oe_pick_ticket.pick_and_hold,
   COALESCE(
      p21_view_clippership_return_10004.shipped_date,
      oe_pick_ticket.ship_date
   ) c_ship_date,
   oe_pick_ticket.invoice_no,
   oe_pick_ticket.auxiliary,
   oe_pick_ticket.direct_shipment,
   oe_pick_ticket.delete_flag,
   oe_pick_ticket.order_no,
   oe_pick_ticket.total_tax,
   freight_code.freight_cd,
   oe_pick_ticket.freight_code_uid,
   oe_hdr.packing_basis,
   oe_hdr.company_id,
   oe_pick_ticket.oe_pick_ticket_type_cd,
   oe_pick_ticket.outgoing_freight_cost,
   CASE WHEN oe_pick_ticket_type_cd = 1921 THEN 'Parts Pick Ticket' WHEN oe_pick_ticket_type_cd = 1922 THEN 'Service Pick Ticket' WHEN oe_pick_ticket.direct_shipment = 'Y' THEN 'Direct Shipment' WHEN oe_pick_ticket.auxiliary = 'Y' THEN 'Auxiliary Pick Ticket' WHEN oe_pick_ticket.pick_and_hold = 'Y' THEN CASE WHEN oe_hdr.packing_basis = 'Tag and Hold' THEN 'Tag And Hold' ELSE 'Pick And Hold' END ELSE CASE ptshipment.transaction_type_cd WHEN 222 THEN 'Shipped via Order Entry' ELSE 'Regular Pick Ticket' END END + CASE WHEN COALESCE(
      p21_view_clippership_return_10004.clippership_return_uid,
      0
   ) <> 0 THEN CASE system_setting.value WHEN 'Y' THEN ' (Quick Ship)' ELSE ' (Clippership)' END WHEN COALESCE(ptshipment.shipment_uid, 0) <> 0 THEN ' (' + carriertype.code_description + ')' ELSE '' END shipment_type_display,
   CASE ptshipment.transaction_type_cd WHEN 222 THEN oe_hdr.order_no ELSE oe_pick_ticket.pick_ticket_no END transaction_no,
   ptshipment.shipment_uid shipment_uid,
   p21_view_clippership_return_10004.clippership_return_uid clippership_return_uid,
   address.carrier_type_cd,
   COALESCE(
      ptshipment.ship_location_id,
      oe_pick_ticket.location_id
   ),
   ptshipment.transaction_type_cd transaction_type_cd,
   0 strategic_freight_out,
   oe_pick_ticket.carrier_id,
   company_strategic_pricing.retail_warehouse_separate_flag,
   oe_hdr.front_counter front_counter_order,
   location.strategic_retail_location_flag,
   oe_hdr.customer_id,
   CASE invoice_hdr.record_type_cd WHEN 2594 THEN invoice_hdr.record_type_reference_no ELSE '' END,
   COALESCE(
      drv_lot_bill_packing_basis.protect_packing_basis,
      'N'
   ) protect_packing_basis,
   ups_shipping_route.route_description,
   oe_pick_ticket_ups.shipping_route_stop,(driver.first_name + ' ' + driver.last_name) driver_name,
   CASE WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'N' THEN 'N' WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'Y'
   AND oe_pick_ticket_ups.shipping_route_uid IS NULL THEN 'Y' WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'Y'
   AND oe_pick_ticket_ups.shipping_route_uid IS NOT NULL THEN 'R' WHEN oe_pick_ticket_ups.sent_to_roadnet_flag = 'P' THEN 'P' ELSE 'N' END roadnet_status,
   oe_pick_ticket.rfnav_pick_status_cd
   /*MAIN FROM CLAUSE*/
FROM
   oe_pick_ticket
   INNER JOIN oe_hdr ON oe_hdr.order_no = oe_pick_ticket.order_no
   LEFT JOIN p21_view_clippership_return_10004 ON (
      p21_view_clippership_return_10004.pick_ticket_no = oe_pick_ticket.pick_ticket_no
   )
   AND (
      p21_view_clippership_return_10004.delete_flag = 'N'
   )
   LEFT JOIN freight_code ON (
      freight_code.freight_code_uid = oe_pick_ticket.freight_code_uid
   )
   LEFT JOIN shipment AS ptshipment ON (ptshipment.row_status_flag = 2175)
   AND (
      ptshipment.transaction_type_cd = 1000
      AND ptshipment.transaction_no = oe_pick_ticket.pick_ticket_no
   )
   LEFT JOIN address ON (
      address.id = COALESCE(
         ptshipment.carrier_id,
         oe_pick_ticket.carrier_id
      )
   )
   LEFT JOIN code_p21 AS carriertype ON (carriertype.code_no = address.carrier_type_cd)
   LEFT JOIN company_strategic_pricing ON company_strategic_pricing.company_id = oe_pick_ticket.company_id
   LEFT JOIN location ON location.location_id = oe_hdr.location_id
   AND location.company_id = oe_pick_ticket.company_id
   LEFT JOIN invoice_hdr ON invoice_hdr.invoice_no = cast(oe_pick_ticket.invoice_no as varchar(10))
   LEFT JOIN (
      SELECT
         DISTINCT(oe_pick_ticket.pick_ticket_no),
         'Y' protect_packing_basis
      FROM
         oe_pick_ticket
         INNER JOIN oe_pick_ticket_detail ON oe_pick_ticket.pick_ticket_no = oe_pick_ticket_detail.pick_ticket_no
         INNER JOIN oe_line ON oe_line.line_no = oe_pick_ticket_detail.oe_line_no
         AND oe_line.order_no = oe_pick_ticket.order_no
         AND oe_line.detail_type <> 3
         LEFT JOIN oe_line_lot_billing ON oe_line.oe_line_uid = oe_line_lot_billing.oe_line_uid
      WHERE
         (
            (oe_line_lot_billing.oe_line_uid IS NULL)
            OR (oe_line_lot_billing.packing_basis IS NULL)
         )
         AND (
            (oe_line_lot_billing.price_basis IS NULL)
            OR (oe_line_lot_billing.price_basis <> 'N')
         )
   ) AS drv_lot_bill_packing_basis ON drv_lot_bill_packing_basis.pick_ticket_no = oe_pick_ticket.pick_ticket_no
   LEFT JOIN oe_pick_ticket_ups ON oe_pick_ticket_ups.pick_ticket_no = oe_pick_ticket.pick_ticket_no
   LEFT JOIN shipping_route AS ups_shipping_route ON ups_shipping_route.shipping_route_uid = oe_pick_ticket_ups.shipping_route_uid
   LEFT JOIN contacts AS driver ON driver.id = oe_pick_ticket_ups.driver_id
   INNER JOIN system_setting ON (system_setting.name = 'epicor_manifest_enabled')
   /*MAIN WHERE CLAUSE*/
WHERE
   (
      NOT (
         oe_pick_ticket.delete_flag = 'Y'
         AND oe_pick_ticket.pick_and_hold = 'Y'
      )
   )
   AND (oe_hdr.order_no = 1538243)
   /*MAIN GROUP BY CLAUSE*/
   /*MAIN HAVING CLAUSE*/
   /*MAIN ORDER BY CLAUSE*/
