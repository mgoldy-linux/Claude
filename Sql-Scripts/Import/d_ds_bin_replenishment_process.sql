--DS d_ds_bin_replenishment_process
SELECT bin_replenishment_order.bin_replenishment_order_uid, bin_replenishment.rep_source_cd, putaway_zone.bin_replenishment_user, bin_replenishment_order.row_status_flag, pick_zone.bin_replenishment_interval, bin_replenishment_order.date_notified, 
bin_replenishment_order.date_last_modified, bin_replenishment_order.last_maintained_by, bin_replenishment_order.alert_sent_flag, bin_replenishment_order.date_created, bin_replenishment_order.replenishment_order_user, workbench_x_users.users_id AS c_workbench_users_id 
FROM bin_replenishment_order INNER JOIN bin_replenishment 
ON (bin_replenishment_order.bin_replenishment_uid = bin_replenishment.bin_replenishment_uid) 
INNER JOIN bin 
ON (bin.bin_uid = bin_replenishment.bin_uid) 
LEFT JOIN bin_zone putaway_zone 
ON (putaway_zone.bin_zone_uid = bin.putaway_zone_uid) 
LEFT JOIN bin_zone pick_zone 
ON (pick_zone.bin_zone_uid = bin.pick_zone_uid) 
LEFT JOIN workbench_queue 
ON workbench_queue.document_no = bin_replenishment_order.bin_replenishment_order_uid AND workbench_queue.document_type_cd = 1685 AND workbench_queue.rf_picking_status_cd <> 1734 
LEFT JOIN workbench_x_users 
ON workbench_x_users.workbench_x_users_uid = workbench_queue.workbench_x_users_uid	
INNER JOIN	(SELECT	bin_replenishment.bin_replenishment_uid 
FROM	bin_replenishment INNER JOIN bin rep_bin 
ON (rep_bin.bin_uid = bin_replenishment.bin_uid) 
INNER JOIN inv_bin 
ON (inv_bin.inv_mast_uid = bin_replenishment.inv_mast_uid) AND (inv_bin.location_id = rep_bin.location_id) AND (inv_bin.company_id = rep_bin.company_id) 
INNER JOIN bin from_bin 
ON (from_bin.bin_id = inv_bin.bin) AND (from_bin.location_id = inv_bin.location_id) AND (from_bin.company_id = inv_bin.company_id) 
INNER JOIN bin_zone 
ON (bin_zone.bin_zone_uid = from_bin.putaway_zone_uid) 
LEFT JOIN	bin_type 
ON (bin_type.bin_type_uid = from_bin.bin_type_uid) 
WHERE	inv_bin.quantity > 0 AND	bin_replenishment.bin_uid <> from_bin.bin_uid AND bin_zone.bin_zone_uid = COALESCE(bin_replenishment.bin_zone_uid, bin_zone.bin_zone_uid) AND (COALESCE(bin_type.quarantine_flag, 'N') <> 'Y') 
GROUP BY bin_replenishment.bin_replenishment_uid ) AS drv_source_bins 
ON (drv_source_bins.bin_replenishment_uid = bin_replenishment.bin_replenishment_uid) 
WHERE bin_replenishment_order.row_status_flag = 702 OR bin_replenishment_order.row_status_flag = 704 AND bin_replenishment_order.alert_sent_flag <> 'Y'