-- check current settings df0df016565

Select	row_status_flag  --701
From	vessel_receipts_container
WHERE vessel_receipts_container_uid IN (354)
;

Select	row_status_flag  --972
From container_receipts_hdr
WHERE container_receipts_hdr_uid IN (1255)
;

Select	row_status_flag   --701
FROM	vessel_receipts_line
WHERE vessel_receipts_hdr_uid =  353
AND vessel_receipts_container_uid= 354
AND row_status_flag = 701