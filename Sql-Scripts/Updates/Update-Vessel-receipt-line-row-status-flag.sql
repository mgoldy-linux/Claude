 -- on the phone with Jeff
 Select *
 from vessel_receipts_line  --.row_status_flag.
 where vessel_receipts_hdr_uid = 1663 and po_line_uid = 78595

 update vessel_receipts_line
 set row_status_flag = 976
 where vessel_receipts_hdr_uid = 1663 and po_line_uid = 78595

Select *
from vessel_receipts_line  --.row_status_flag.
where vessel_receipts_hdr_uid = 1663 and po_line_uid = 78595

/*
 select po_line_uid,*
 from po_line
 where po_no = 4010774 and po_line_uid = 78599 

 Select distinct row_status_flag
 from vessel_receipts_line 
 */