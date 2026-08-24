--Transfer History Tab on Item Master Inquiry: 2100038820 (0-99999999)
SELECT
   inventory_receipts_line.receipt_number,
   inventory_receipts_line.line_number,
   transfer_hdr.transfer_no,
   inventory_receipts_line.po_line_number,
   inventory_receipts_line.date_created,
   location.location_id,
   location.location_name,
   inventory_receipts_line.unit_of_measure,
   inventory_receipts_line.unit_size,
   inventory_receipts_line.unit_quantity,
   transfer_line.qty_to_transfer,
   transfer_hdr.from_location_id,
   inventory_receipts_line.inv_mast_uid,
   transfer_line.cost,
   ' ' pricing_unit,
   CASE transfer_line.row_status WHEN 1 THEN 'Y' ELSE 'N' END complete,
   transfer_line.delete_flag,
   transfer_line.qty_received,
   COALESCE(drv_landed_cost_receipt.total_landed_cost_amt, 0) + COALESCE(
      drv_landed_cost_container.total_landed_cost_amt,
      0
   ) + Coalesce(drv_landed_cost_vessel.total_landed_cost_amt, 0) 'landed_cost_sum_amt',
   0 currency_id,
   CASE COALESCE(
      (
         SELECT
            value
         FROM
            system_setting
         WHERE
            name = 'enable_gallons_display'
      ),
      'N'
   ) WHEN 'N' THEN 0 ELSE COALESCE(item_uom_gallon.unit_size, 0) END gallons_unit_size,
   transfer_shipment_hdr.carrier_id,
   transfer_shipment_hdr.carrier_tracking_no,
   transfer_shipment_hdr.shipping_route_uid,
   transfer_shipment_line.sku_qty_shipped,
   oe_line_po.order_number,
   oe_line_po.line_number,
   CASE COALESCE(oe_hdr.order_type, 706) WHEN 1343 THEN 'CRO' WHEN 1344 THEN 'CUO' WHEN 1706 THEN 'SO' WHEN 1877 THEN 'MRO' ELSE (
      CASE COALESCE(oe_line_po.order_number, 0) WHEN 0 THEN NULL ELSE 'OE' END
   ) END cc_order_type
   /*MAIN FROM CLAUSE*/
FROM
   inventory_receipts_line
   INNER JOIN inventory_receipts_hdr ON inventory_receipts_hdr.receipt_number = inventory_receipts_line.receipt_number
   INNER JOIN transfer_shipment_hdr ON transfer_shipment_hdr.transfer_shipment_no = inventory_receipts_hdr.po_number
   INNER JOIN transfer_hdr ON transfer_hdr.transfer_no = transfer_shipment_hdr.transfer_no
   INNER JOIN transfer_shipment_line ON transfer_shipment_line.transfer_shipment_hdr_uid = transfer_shipment_hdr.transfer_shipment_hdr_uid
   AND transfer_shipment_line.transfer_line_no = inventory_receipts_line.po_line_number
   INNER JOIN transfer_line ON transfer_line.transfer_no = transfer_hdr.transfer_no
   AND transfer_line.line_no = transfer_shipment_line.transfer_line_no
   INNER JOIN location ON location.location_id = transfer_hdr.to_location_id
   LEFT JOIN p21_view_container_receipts_line_ext ON p21_view_container_receipts_line_ext.receipt_number = inventory_receipts_line.receipt_number
   AND p21_view_container_receipts_line_ext.receipt_line_number = inventory_receipts_line.line_number
   LEFT JOIN (
      SELECT
         lc_driver_x_tran_detail.transaction_number,
         lc_driver_x_tran_detail.transaction_type_cd,
         lc_driver_x_tran_detail.line_no,
         SUM(lc_driver_x_tran_detail.landed_cost_amt) 'total_landed_cost_amt'
      FROM
         lc_driver_x_tran_detail
      WHERE
         lc_driver_x_tran_detail.transaction_type_cd = 1223
      GROUP BY
         lc_driver_x_tran_detail.transaction_number,
         lc_driver_x_tran_detail.transaction_type_cd,
         lc_driver_x_tran_detail.line_no
   ) AS drv_landed_cost_receipt ON drv_landed_cost_receipt.transaction_number = inventory_receipts_hdr.receipt_number
   AND drv_landed_cost_receipt.line_no = inventory_receipts_line.line_number
   LEFT JOIN (
      SELECT
         lc_driver_x_tran_detail.transaction_number,
         lc_driver_x_tran_detail.transaction_type_cd,
         lc_driver_x_tran_detail.line_no,
         SUM(lc_driver_x_tran_detail.landed_cost_amt) 'total_landed_cost_amt'
      FROM
         lc_driver_x_tran_detail
      WHERE
         lc_driver_x_tran_detail.transaction_type_cd = 1984
      GROUP BY
         lc_driver_x_tran_detail.transaction_number,
         lc_driver_x_tran_detail.transaction_type_cd,
         lc_driver_x_tran_detail.line_no
   ) AS drv_landed_cost_container ON drv_landed_cost_container.transaction_number = p21_view_container_receipts_line_ext.lc_transaction_number
   AND drv_landed_cost_container.line_no = p21_view_container_receipts_line_ext.lc_line_no
   LEFT JOIN (
      SELECT
         lc_driver_x_tran_detail.transaction_number,
         lc_driver_x_tran_detail.transaction_type_cd,
         lc_driver_x_tran_detail.line_no,
         SUM(lc_driver_x_tran_detail.landed_cost_amt) 'total_landed_cost_amt'
      FROM
         lc_driver_x_tran_detail
      WHERE
         lc_driver_x_tran_detail.transaction_type_cd = 1674
      GROUP BY
         lc_driver_x_tran_detail.transaction_number,
         lc_driver_x_tran_detail.transaction_type_cd,
         lc_driver_x_tran_detail.line_no
   ) AS drv_landed_cost_vessel ON drv_landed_cost_vessel.transaction_number = p21_view_container_receipts_line_ext.vessel_receipts_hdr_uid
   AND drv_landed_cost_vessel.line_no = p21_view_container_receipts_line_ext.line_no
   LEFT Join system_setting as system_setting_Gallon ON (
      system_setting_Gallon.configuration_id = 0
      AND system_setting_Gallon.name = 'Gallon_UOM'
   )
   LEFT JOIN item_uom as item_uom_gallon ON (
      item_uom_gallon.inv_mast_uid = transfer_line.inv_mast_uid
   )
   AND (
      item_uom_gallon.unit_of_measure = system_setting_Gallon.value
   )
   LEFT JOIN oe_line_po ON (oe_line_po.po_no = transfer_line.transfer_no)
   AND (
      oe_line_po.po_line_number = transfer_line.line_no
   )
   AND (oe_line_po.connection_type = 'T')
   LEFT JOIN oe_hdr ON (oe_hdr.order_no = oe_line_po.order_number)
   /*MAIN WHERE CLAUSE*/
WHERE
   inventory_receipts_hdr.approved = 'Y'
   AND inventory_receipts_hdr.receipt_type = 'T'
   AND inventory_receipts_line.qty_received <> 0 and transfer_hdr.transfer_no = 8002220
   /*MAIN GROUP BY CLAUSE*/
   /*MAIN HAVING CLAUSE*/
   /*MAIN ORDER BY CLAUSE*/
