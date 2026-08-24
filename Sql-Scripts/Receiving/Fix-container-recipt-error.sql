-- 701 = "Complete", 704 = "Active"
-- 971 = "Unapproved", 972 "Approved"
-- 702 = "Open"

UPDATE	vessel_receipts_container
SET		row_status_flag = 704 --701
		,date_last_modified = CURRENT_TIMESTAMP
		,last_maintained_by = 'P21_DBA_1426197'
WHERE vessel_receipts_container_uid IN (484)


UPDATE container_receipts_hdr
SET		row_status_flag = 971 --972
		,date_last_modified = CURRENT_TIMESTAMP
		,last_maintained_by = 'P21_DBA_1426197'
WHERE container_receipts_hdr_uid IN (1734)

UPDATE	vessel_receipts_line
SET		row_status_flag = 702  --701
		,date_last_modified = CURRENT_TIMESTAMP
		,last_maintained_by = 'P21_DBA_1426197'
FROM	vessel_receipts_line
WHERE vessel_receipts_hdr_uid =  483
AND vessel_receipts_container_uid= 484
AND row_status_flag = 701

EXECUTE('p21_db_sql_ins "0df016565", "Scopus 1426197"')
;