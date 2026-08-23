--Form View Tab on Process Transactions: 9312
SELECT
   process_x_transaction.process_x_transaction_uid,
   process_x_transaction.transaction_type,
   process_x_transaction.transaction_no,
   process_x_transaction.transaction_line_no,
   process_x_transaction.process_uid,
   process_x_transaction.raw_inv_mast_uid,
   process_x_transaction.finished_inv_mast_uid,
   process_x_transaction.begin_date,
   process_x_transaction.estimated_date,
   process_x_transaction.expected_date,
   process_x_transaction.raw_qty_requested,
   process_x_transaction.raw_qty_allocated,
   process_x_transaction.location_id,
   process_x_transaction.date_created,
   process_x_transaction.date_last_modified,
   process_x_transaction.last_maintained_by,
   process_x_transaction.row_status_flag,
   process_x_transaction.process_cd,
   process_x_transaction.process_name,
   inv_mast_raw.item_id,
   inv_mast_raw.item_desc,
   inv_mast_fin.item_id,
   inv_mast_fin.item_desc,
   inv_mast_raw.track_lots,
   address.name,
   process_x_transaction.accumulated_cost_of_processing,
   process_x_transaction.qty_completed,
   process_x_transaction.disposition,
   process_x_transaction_ext.raw_qty_available 'qty_available',
   process_x_transaction.parent_process_x_trans_uid,
   process_x_transaction.extended_description,
   inv_loc.track_bins,
   COALESCE(
      (
         SELECT
            SUM(
               process_x_transaction_detail.qty_in + process_x_transaction_detail.qty_partially_received
            )
         FROM
            process_x_transaction_detail
         WHERE
            (
               process_x_transaction_detail.row_status_flag <> 700
            )
            AND (
               process_x_transaction_detail.process_x_transaction_uid = process_x_transaction.process_x_transaction_uid
            )
            AND (process_x_transaction_detail.sequence_no = 1)
      ),
      0
   ) C_TotalQtyIn,
   'Y' C_RetrievedRow,
   process_x_transaction.raw_qty_allocated + process_x_transaction.qty_completed - process_x_transaction.raw_qty_requested C_IfZeroAllAllocatedToProcess,
   process_x_transaction.raw_yield_qty,
   process_x_transaction.finished_yield_qty,
   process_x_transaction.raw_yield_uom,
   process_x_transaction.finished_yield_uom,
   process_x_transaction.process_desc,
   company.company_id,
   company.company_name,
   0.0000 finished_qty_requested,
   0.0000 raw_unit_qty_started,
   'N' viewed_note,
   'N' viewed_note_route,
   item_uom_raw.unit_size raw_yield_unit_size,
   item_uom_fin.unit_size finished_yield_unit_size,
   0.0000 finished_unit_qty_requested,
   CAST(
      process_x_transaction.raw_qty_requested / item_uom_raw.unit_size AS Decimal(19, 9)
   ) raw_unit_qty_requested,
   CAST(
      process_x_transaction.raw_qty_allocated / item_uom_raw.unit_size AS Decimal(19, 9)
   ) raw_unit_qty_allocated,
   'N' print_itempackage_labels,
   0.0000 C_TotalQtyLost,
   process_x_transaction.finished_qty_completed,
   process_x_transaction.report_printed_flag,
   process_x_transaction.completed_date,
   process_x_transaction.capture_usage_flag,
   'N' print_traveler_form,
   process_x_transaction.retrieved_by_wms,
   process_x_transaction_ext.raw_item_revision_uid,
   process_x_transaction_ext.finished_item_revision_uid,
   process_x_transaction_ext.raw_revision_level,
   process_x_transaction_ext.finished_revision_level,
   process_x_transaction_ext.raw_use_revisions_flag,
   process_x_transaction_ext.finished_use_revisions_flag,
   NULL receipt_no,
   NULL receipt_line_no,
   inv_mast_raw.product_type,
   inv_mast_fin.product_type
   /*MAIN FROM CLAUSE*/
FROM
   process_x_transaction
   INNER JOIN p21_view_process_x_transaction_ext AS process_x_transaction_ext ON process_x_transaction_ext.process_x_transaction_uid = process_x_transaction.process_x_transaction_uid
   LEFT OUTER JOIN inv_mast inv_mast_raw ON inv_mast_raw.inv_mast_uid = process_x_transaction.raw_inv_mast_uid
   LEFT OUTER JOIN inv_mast inv_mast_fin ON inv_mast_fin.inv_mast_uid = process_x_transaction.finished_inv_mast_uid
   LEFT OUTER JOIN address ON address.id = process_x_transaction.location_id
   INNER JOIN inv_loc ON inv_loc.location_id = process_x_transaction.location_id
   AND inv_loc.inv_mast_uid = inv_mast_raw.inv_mast_uid
   INNER JOIN location ON location.location_id = process_x_transaction.location_id
   INNER JOIN company ON company.company_id = location.company_id
   LEFT OUTER JOIN item_uom AS item_uom_raw ON item_uom_raw.inv_mast_uid = process_x_transaction.raw_inv_mast_uid
   AND item_uom_raw.unit_of_measure = process_x_transaction.raw_yield_uom
   LEFT OUTER JOIN item_uom AS item_uom_fin ON item_uom_fin.inv_mast_uid = process_x_transaction.finished_inv_mast_uid
   AND item_uom_fin.unit_of_measure = process_x_transaction.finished_yield_uom
   /*MAIN WHERE CLAUSE*/
WHERE
   (process_x_transaction.row_status_flag <> 700)
   /*MAIN GROUP BY CLAUSE*/
   /*MAIN HAVING CLAUSE*/
   /*MAIN ORDER BY CLAUSE*/
