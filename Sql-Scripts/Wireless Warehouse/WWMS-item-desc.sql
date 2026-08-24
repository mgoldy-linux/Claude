                        SELECT
  TOP 100 h.adjustment_number,
  h.company_id,
  company.company_name,
  h.location_id,
  address.name,
  h.reason_id,
  h.period,
  h.year_for_period,
  h.approved,
  h.delete_flag,
  h.date_created,
  h.date_last_modified,
  h.last_maintained_by,
  h.parent_trans_type_cd,
  h.parent_trans_no,
  h.paperless_count_flag,
  '' c_rf_count_number,
  '' c_rf_current_bin,
  '' c_rf_bin,
  '' c_rf_item_id,
  '' c_rf_tag,
  '' c_rf_lot_cd,
  '' c_rf_serial_number,
  '' c_rf_reason,
  '' c_rf_new_qty,
  '' c_rf_uom,
  '' c_rf_package,
  '' c_rf_qty_per,
  '' c_rf_track_lots,
  '' c_rf_serialized,
  '' c_rf_tags_on,
  '' c_rf_current_item_id,
  0.0 units_on_hand,
  'LB' response_flag,
  h.rf_last_line_no,
  h.rf_count_in_process_flag,
  1512 row_status_flag,
  0 c_unit_size,
  '' c_rf_trans_revision_level,
  NULL c_rf_item_revision_uid,
  h.show_all_items_flag,
  h.display_found_items_flag,
  item_id,m.item_desc
FROM
  inv_adj_hdr h
  INNER JOIN company ON (company.company_id = h.company_id)
  INNER JOIN address ON (h.location_id = address.id)
  INNER JOIN location ON (location.company_id = h.company_id)
  AND (location.location_id = h.location_id)
  join inv_adj_line l
on h.adjustment_number = l.adjustment_number
join inv_mast m
on l.inv_mast_uid = m.inv_mast_uid
WHERE
  (
    h.adjustment_number = 7011786 and item_id in  ('2101012560','2101012552','2101012553')
  )
  AND (h.paperless_count_flag = 'Y')