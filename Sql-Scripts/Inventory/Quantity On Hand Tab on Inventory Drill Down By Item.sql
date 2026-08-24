--Quantity On Hand Tab on Inventory Drill Down By Item: 2103002981 (6305-AAC4SRI2-60Q)
SELECT
   inv_tran.trans_type,
   inv_tran.document_no,
   inv_tran.date_created,
   CAST(inv_tran.quantity / 1 AS Decimal(19, 9)) quantity,
   inv_tran.last_maintained_by,
   CAST(
      inv_tran.on_hand_before_trans / 1 AS Decimal(19, 9)
   ) on_hand_before_trans,
   inv_tran.inv_mast_uid,
   inv_tran.date_last_modified,
   inv_tran.line_no,
   inv_adj_hdr.parent_trans_no,
   NULL,
   inv_tran.unit_of_measure
FROM
   inv_tran
   INNER JOIN inv_mast ON inv_mast.inv_mast_uid = inv_tran.inv_mast_uid
   LEFT JOIN inv_adj_hdr ON inv_adj_hdr.adjustment_number = inv_tran.document_no
   AND inv_adj_hdr.parent_trans_type_cd = 1047
WHERE
   (inv_tran.location_id = 510)
   AND (inv_mast.item_id = '2103002981')
   AND (
      (inv_tran.quantity <> 0)
      OR (
         inv_tran.quantity = 0
         AND inv_tran.trans_type = 'IM'
      )
   )
   AND inv_tran.date_created > '2024-01-01'
UNION
SELECT
   'Adjustment' trans_type,
   cycle_count_accuracy.adjustment_number document_no,
   cycle_count_accuracy.date_last_modified,
   0 quantity,
   cycle_count_accuracy.last_maintained_by,
   COALESCE(
      cycle_count_detail.qty_on_hand_at_physical_count,
      0,
      cycle_count_detail.qty_on_hand_at_physical_count
   ) / 1 on_hand_before_trans,
   cycle_count_detail.inv_mast_uid,
   cycle_count_accuracy.date_last_modified,
   0 line_no,
   cycle_count_accuracy.cycle_count_hdr_uid parent_trans_no,
   inv_adj_line.unit_of_measure,
   NULL
FROM
   cycle_count_hdr
   INNER JOIN cycle_count_loc_criteria ON cycle_count_loc_criteria.cycle_count_loc_criteria_uid = cycle_count_hdr.cycle_count_loc_criteria_uid
   INNER JOIN cycle_count_detail ON cycle_count_detail.cycle_count_hdr_uid = cycle_count_hdr.cycle_count_hdr_uid
   INNER JOIN inv_mast ON inv_mast.inv_mast_uid = cycle_count_detail.inv_mast_uid
   INNER JOIN cycle_count_accuracy ON cycle_count_accuracy.cycle_count_hdr_uid = cycle_count_hdr.cycle_count_hdr_uid
   INNER JOIN inv_adj_hdr ON inv_adj_hdr.adjustment_number = cycle_count_accuracy.adjustment_number
   LEFT JOIN inv_adj_line ON inv_adj_line.adjustment_number = cycle_count_accuracy.adjustment_number
   AND inv_adj_line.inv_mast_uid = cycle_count_detail.inv_mast_uid
   LEFT JOIN system_setting system_setting_count ON system_setting_count.name = 'include_zero_cc_adjustment_flag'
WHERE
   cycle_count_hdr.row_status_flag = 701
   AND cycle_count_loc_criteria.location_id = 510
   AND inv_mast.item_id = '2103002981'
   AND inv_adj_hdr.date_created > '2024-01-01'
   AND inv_adj_hdr.approved = 'Y'
   AND inv_adj_hdr.delete_flag = 'N'
   AND inv_adj_line.line_number IS NULL
   AND COALESCE(system_setting_count.value, 'Y') = 'Y'
ORDER BY
   date_created DESC,
   document_no DESC
