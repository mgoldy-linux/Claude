use P21Training;

-- Legacy/non-P21 view cleanup (Deploy-Guides\ds_view_open_rma_value-retirement.md), not SA-51376.
-- The re-added "Open Total Value" header renders Right-aligned (alignment=1, baked into its
-- base create text() blob) instead of Center-aligned like its neighbors Carrier/Class 1
-- (alignment=2, via an explicit override row layered on top of their own create blobs, which
-- also default to alignment=1/0 respectively). Adds the same kind of override row.
--
-- custom_objects_detail_uid is NOT an identity column -- it's governed by a real P21 counter
-- (id='custom_objects_detail', seq_custom_objects_detail). That sequence was found DRIFTED:
-- current_value 319020 vs. real table MAX 319025 (the client's own recent re-add already
-- outpaced it). Resyncing via p21_set_counter before drawing a new value, per
-- feedback_p21_counter_drift -- do NOT use MAX(custom_objects_detail_uid)+1 directly.

-- === BEFORE: confirm the drift and the sibling pattern ===
SELECT current_value FROM sys.sequences WHERE name = 'seq_custom_objects_detail';
SELECT MAX(custom_objects_detail_uid) AS max_uid FROM custom_objects_detail;

SELECT custom_objects_detail_uid, sequence_no, object_name, attribute_name, attribute_value, row_status_flag
FROM custom_objects_detail
WHERE custom_objects_uid = 158
  AND object_name IN ('ufc_oe_hdr_carrier_id_t','ufc_oe_hdr_class_1id_t','ufc_p21_view_open_rma_report_open_total_value_t')
ORDER BY object_name, attribute_name;

-- === Resync the counter to the real table value ===
EXEC p21_set_counter @counter_id = 'custom_objects_detail', @set_to_table_value = 1;

-- === Draw the next safe ID and insert the alignment override ===
DECLARE @new_uid BIGINT = NEXT VALUE FOR dbo.seq_custom_objects_detail;

INSERT INTO custom_objects_detail
    (custom_objects_detail_uid, custom_objects_uid, sequence_no, object_name, attribute_name, attribute_value,
     row_status_flag, date_created, created_by, date_last_modified, last_maintained_by)
VALUES
    (@new_uid, 158, 63, 'ufc_p21_view_open_rma_report_open_total_value_t', 'alignment', '2',
     704, GETDATE(), 'mgoldyn', GETDATE(), 'mgoldyn');

SELECT @new_uid AS inserted_uid;

-- === AFTER ===
SELECT custom_objects_detail_uid, sequence_no, object_name, attribute_name, attribute_value, row_status_flag
FROM custom_objects_detail
WHERE custom_objects_uid = 158
  AND object_name = 'ufc_p21_view_open_rma_report_open_total_value_t'
ORDER BY attribute_name;
