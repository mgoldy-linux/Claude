SELECT
   oe_line_schedule.release_date,
   oe_line_schedule.oe_line_schedule_uid,
   oe_line_schedule.order_no,
   inv_mast.item_id,
   oe_line_schedule.release_no,
   oe_line_schedule.release_qty,
   oe_line_schedule.allocated_qty,
   oe_line_schedule.expedite_value,
   oe_line_schedule.expedite_type,
   oe_line_schedule.pick_value,
   oe_line_schedule.pick_type,
   oe_line_schedule.printed,
   oe_line_schedule.date_created,
   oe_line_schedule.date_last_modified,
   oe_line_schedule.last_maintained_by,
   oe_line_schedule.line_no,
   ' ',
   oe_line_schedule.pick_date,
   0.000000000,
   0.000000000,
   inv_mast.item_desc,
   oe_line_schedule.expedite_date,
   oe_line.unit_size,
   CAST(
      (oe_line_schedule.release_qty / oe_line.unit_size) AS Decimal(19, 9)
   ),
   CAST(
      (
         oe_line_schedule.allocated_qty / oe_line.unit_size
      ) AS Decimal(19, 9)
   ),
   oe_line_schedule.disposition,
   oe_line_schedule.qty_picked,
   oe_line_schedule.qty_invoiced,
   oe_line_schedule.qty_staged,
   oe_line_schedule.qty_canceled,
   oe_line.unit_of_measure,
   oe_line_schedule.inv_mast_uid,
   0.0000 orig_allocated,
   oe_line.assembly,
   oe_line.detail_type,
   oe_line.oe_line_uid,
   oe_line.parent_oe_line_uid,
   oe_line_schedule.release_status_flag
FROM
   oe_line_schedule
   INNER JOIN oe_line ON oe_line.order_no = oe_line_schedule.order_no
   AND oe_line.line_no = oe_line_schedule.line_no
   INNER JOIN inv_mast ON inv_mast.inv_mast_uid = oe_line_schedule.inv_mast_uid
WHERE
   oe_line_schedule.order_no = 1062552
ORDER BY
   oe_line_schedule.order_no ASC,
   oe_line_schedule.line_no ASC,
   oe_line_schedule.release_no ASC